import ActionKit
import Foundation

extension ActionExecutor {
  func executeOpenFolder(_ path: String) async -> ActionResult {
    guard let path = normalizedRequiredString(path) else {
      return invalidInputResult("Folder path is empty")
    }

    let expanded = (path as NSString).expandingTildeInPath
    let url = URL(fileURLWithPath: expanded)

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
      isDirectory.boolValue
    else {
      return notFoundResult("Folder does not exist")
    }

    let ok = await dependencies.workspace.open(url)
    guard ok else {
      return openFailedResult("Failed to open folder")
    }
    return .success
  }

  func executeOpenURL(_ urlString: String) async -> ActionResult {
    guard let urlString = normalizedRequiredString(urlString),
      let url = URL(string: urlString),
      isValidOpenURL(url)
    else {
      return invalidInputResult("Invalid URL")
    }

    let ok = await dependencies.workspace.open(url)
    guard ok else {
      return openFailedResult("Failed to open URL")
    }
    return .success
  }

  func executeLaunchApplication(_ applicationIdentifierOrPath: String) async -> ActionResult {
    guard
      let applicationIdentifierOrPath = normalizedRequiredString(applicationIdentifierOrPath)
    else {
      return invalidInputResult("Empty application name, bundle identifier, or .app bundle path")
    }

    if let pathResult = applicationPathResult(for: applicationIdentifierOrPath) {
      switch pathResult {
      case .valid(let appURL):
        return await openApplication(
          at: appURL, failureMessage: "Failed to launch application at path")
      case .missing:
        return notFoundResult("Application path does not exist")
      case .invalid(let message):
        return invalidInputResult(message)
      }
    }

    if let application = await applicationURL(forIdentifierOrName: applicationIdentifierOrPath) {
      return await openApplication(
        at: application.url,
        failureMessage: application.failureMessage
      )
    }

    return notFoundResult("Unable to resolve application")
  }

  func executeRunShortcut(_ shortcutName: String) async -> ActionResult {
    guard let shortcutName = normalizedRequiredString(shortcutName) else {
      return invalidInputResult("Empty shortcut name")
    }

    var components = URLComponents()
    components.scheme = "shortcuts"
    components.host = "run-shortcut"
    components.queryItems = [
      URLQueryItem(name: "name", value: shortcutName)
    ]

    guard let url = components.url else {
      return internalErrorResult("Failed to build shortcut URL")
    }

    let ok = await dependencies.workspace.open(url)
    guard ok else {
      return openFailedResult("Failed to run shortcut")
    }
    return .success
  }

  private func normalizedRequiredString(_ value: String) -> String? {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? nil : trimmed
  }

  private func applicationPathResult(for path: String) -> ApplicationPathResult? {
    guard pathLooksLikeFilePath(path) else { return nil }

    let expanded = (path as NSString).expandingTildeInPath
    let url = URL(fileURLWithPath: expanded)
    guard FileManager.default.fileExists(atPath: url.path) else { return .missing }

    var isDirectory: ObjCBool = false
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
      isDirectory.boolValue,
      url.pathExtension.lowercased() == "app"
    else {
      return .invalid("Application path must point to an .app bundle")
    }
    return .valid(url)
  }

  private func pathLooksLikeFilePath(_ value: String) -> Bool {
    value.hasPrefix("~") || value.hasPrefix("/") || value.contains("/")
  }

  private func isValidOpenURL(_ url: URL) -> Bool {
    guard let scheme = url.scheme?.lowercased(), !scheme.isEmpty else {
      return false
    }

    if scheme == "http" || scheme == "https" {
      return url.host?.isEmpty == false
    }

    return true
  }

  private func applicationURL(forBundleIdentifier bundleIdentifier: String) async -> URL? {
    if let bundleURL = await dependencies.workspace.urlForApplication(
      bundleIdentifier: bundleIdentifier
    ) {
      return bundleURL
    }
    return await dependencies.workspace.urlsForApplications(
      bundleIdentifier: bundleIdentifier
    ).first
  }

  private func applicationURL(forName name: String) async -> URL? {
    await dependencies.workspace.urlForApplication(named: name)
  }

  private func applicationURL(forIdentifierOrName value: String) async -> ResolvedApplication? {
    if value.contains(".") {
      if let url = await applicationURL(forBundleIdentifier: value) {
        return .bundleIdentifier(url)
      }
      if let url = await applicationURL(forName: value) {
        return .name(url)
      }
      return nil
    }
    if let url = await applicationURL(forName: value) {
      return .name(url)
    }
    if let url = await applicationURL(forBundleIdentifier: value) {
      return .bundleIdentifier(url)
    }
    return nil
  }

  private func openApplication(at url: URL, failureMessage: String) async -> ActionResult {
    do {
      try await dependencies.workspace.openApplication(at: url, activates: true)
      return .success
    } catch {
      return openFailedResult(failureMessage)
    }
  }
}

private enum ApplicationPathResult {
  case valid(URL)
  case missing
  case invalid(String)
}

private struct ResolvedApplication {
  let url: URL
  let failureMessage: String

  static func bundleIdentifier(_ url: URL) -> Self {
    .init(url: url, failureMessage: "Failed to launch application by bundle identifier")
  }

  static func name(_ url: URL) -> Self {
    .init(url: url, failureMessage: "Failed to launch application by name")
  }
}

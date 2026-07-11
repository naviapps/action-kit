import AppKit
import Foundation

struct LiveWorkspace: WorkspaceControlling {
  private static let defaultApplicationSearchDirectories = [
    "/Applications",
    "/Applications/Utilities",
    "/System/Applications",
    "/System/Applications/Utilities",
    "/System/Library/CoreServices",
    "~/Applications",
  ]

  private let applicationSearchDirectories: [String]

  init(applicationSearchDirectories: [String] = Self.defaultApplicationSearchDirectories) {
    self.applicationSearchDirectories = applicationSearchDirectories
  }

  func open(_ url: URL) async -> Bool {
    await MainActor.run {
      NSWorkspace.shared.open(url)
    }
  }

  func urlForApplication(bundleIdentifier: String) async -> URL? {
    await MainActor.run {
      NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleIdentifier)
    }
  }

  func urlsForApplications(bundleIdentifier: String) async -> [URL] {
    await MainActor.run {
      NSWorkspace.shared.urlsForApplications(withBundleIdentifier: bundleIdentifier)
    }
  }

  func urlForApplication(named name: String) async -> URL? {
    ApplicationBundleResolver(searchDirectories: applicationSearchDirectories)
      .urlForApplication(named: name)
  }

  func openApplication(at url: URL, activates: Bool) async throws {
    try await openApplicationOnMainActor(at: url, activates: activates)
  }

  @MainActor
  private func openApplicationOnMainActor(at url: URL, activates: Bool) async throws {
    try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
      let configuration = NSWorkspace.OpenConfiguration()
      configuration.activates = activates
      NSWorkspace.shared.openApplication(at: url, configuration: configuration) { _, error in
        if let error {
          continuation.resume(throwing: error)
          return
        }
        continuation.resume()
      }
    }
  }
}

import Foundation

@testable import ActionKitAppKit

struct TestApplicationOpenError: Error {}

actor TestWorkspace: WorkspaceControlling {
  let openURLResult: Bool
  let applicationURLForBundleIdentifier: URL?
  let applicationURLsForBundleIdentifier: [URL]
  let applicationURLForName: URL?
  let openApplicationError: TestApplicationOpenError?
  private(set) var lastOpenedURL: URL?
  private(set) var resolvedBundleIdentifiers: [String] = []
  private(set) var resolvedApplicationNames: [String] = []
  private(set) var openedApplicationURL: URL?
  private(set) var openedApplicationActivates: Bool?

  init(
    openURLResult: Bool = true,
    applicationURLForBundleIdentifier: URL? = nil,
    applicationURLsForBundleIdentifier: [URL] = [],
    applicationURLForName: URL? = nil,
    openApplicationError: TestApplicationOpenError? = nil
  ) {
    self.openURLResult = openURLResult
    self.applicationURLForBundleIdentifier = applicationURLForBundleIdentifier
    self.applicationURLsForBundleIdentifier = applicationURLsForBundleIdentifier
    self.applicationURLForName = applicationURLForName
    self.openApplicationError = openApplicationError
  }

  func open(_ url: URL) async -> Bool {
    lastOpenedURL = url
    return openURLResult
  }

  func urlForApplication(bundleIdentifier: String) async -> URL? {
    resolvedBundleIdentifiers.append(bundleIdentifier)
    return applicationURLForBundleIdentifier
  }

  func urlsForApplications(bundleIdentifier: String) async -> [URL] {
    resolvedBundleIdentifiers.append(bundleIdentifier)
    return applicationURLsForBundleIdentifier
  }

  func urlForApplication(named name: String) async -> URL? {
    resolvedApplicationNames.append(name)
    return applicationURLForName
  }

  func openApplication(at url: URL, activates: Bool) async throws {
    openedApplicationURL = url
    openedApplicationActivates = activates
    if let openApplicationError {
      throw openApplicationError
    }
  }

  var applicationLaunchSnapshot:
    (
      openedApplicationURL: URL?,
      openedApplicationActivates: Bool?,
      resolvedBundleIdentifiers: [String],
      resolvedApplicationNames: [String]
    )
  {
    (
      openedApplicationURL,
      openedApplicationActivates,
      resolvedBundleIdentifiers,
      resolvedApplicationNames
    )
  }
}

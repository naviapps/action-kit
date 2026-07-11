import Foundation

package protocol WorkspaceControlling: Sendable {
  func open(_ url: URL) async -> Bool
  func urlForApplication(bundleIdentifier: String) async -> URL?
  func urlsForApplications(bundleIdentifier: String) async -> [URL]
  func urlForApplication(named name: String) async -> URL?
  func openApplication(at url: URL, activates: Bool) async throws
}

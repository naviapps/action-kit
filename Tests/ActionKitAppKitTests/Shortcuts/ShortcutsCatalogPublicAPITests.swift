import ActionKitAppKit
import XCTest

final class ShortcutsCatalogPublicAPITests: XCTestCase {
  func testPublicCatalogCanBeConfiguredAndInjectedWithoutStartingListing() {
    let catalog = ShortcutsCatalog(timeout: .seconds(2), maximumOutputByteCount: 65_536)
    let load: @Sendable () async throws -> [String] = { try await catalog.shortcutNames() }
    acceptsSendable(catalog)
    acceptsSendable(load)
    acceptsSendable(ShortcutsCatalogError.timedOut)
  }

  private func acceptsSendable<T: Sendable>(_ value: T) {}
}

import XCTest

import ActionKit

final class ActionKindCapabilitiesTests: XCTestCase {
  func testActionRetryBehaviorRawValuesAreCanonical() {
    XCTAssertEqual(
      ActionRetryBehavior.allCases.map(\.rawValue),
      ["safe", "context-dependent", "unsafe"]
    )
  }

  func testActionRetryBehaviorRoundTripsCodable() throws {
    for retryBehavior in ActionRetryBehavior.allCases {
      let data = try JSONEncoder().encode(retryBehavior)

      XCTAssertEqual(try JSONDecoder().decode(ActionRetryBehavior.self, from: data), retryBehavior)
    }
  }

  func testDefaultCapabilitiesAreConservative() {
    let capabilities = ActionKindCapabilities()

    XCTAssertFalse(capabilities.requiresFrontmostApplication)
    XCTAssertFalse(capabilities.requiresFocusedWindow)
    XCTAssertFalse(capabilities.requiresInteractiveSelection)
    XCTAssertFalse(capabilities.isDestructive)
    XCTAssertEqual(capabilities.retryBehavior, .contextDependent)
  }

  func testActionKindCapabilitiesCoverAllCases() {
    let capabilities = Dictionary(
      uniqueKeysWithValues: ActionKind.allCases.map { ($0, $0.capabilities) }
    )

    XCTAssertEqual(
      capabilities,
      [
        .copy: frontmostApplication(retryBehavior: .contextDependent),
        .paste: frontmostApplication(isDestructive: true, retryBehavior: .unsafe),
        .cut: frontmostApplication(isDestructive: true, retryBehavior: .unsafe),
        .undo: frontmostApplication(isDestructive: true, retryBehavior: .unsafe),
        .redo: frontmostApplication(isDestructive: true, retryBehavior: .unsafe),
        .hideFrontmostApplication: frontmostApplication(retryBehavior: .safe),
        .quitFrontmostApplication: frontmostApplication(
          isDestructive: true,
          retryBehavior: .unsafe
        ),
        .volumeUp: unsafe,
        .volumeDown: unsafe,
        .volumeMute: unsafe,
        .mediaPlayPause: unsafe,
        .mediaNext: unsafe,
        .mediaPrevious: unsafe,
        .keyboardShortcut: frontmostApplication(retryBehavior: .unsafe),
        .openURL: unsafe,
        .launchApplication: safe,
        .runShortcut: unsafe,
        .openFolder: unsafe,
        .missionControl: unsafe,
        .showDesktop: unsafe,
        .lockScreen: destructiveUnsafe,
        .sleepMac: destructiveUnsafe,
        .missionControlNextSpace: unsafe,
        .missionControlPreviousSpace: unsafe,
        .missionControlAppExpose: unsafe,
        .brightnessUp: unsafe,
        .brightnessDown: unsafe,
        .toggleAppearance: destructiveUnsafe,
        .showNotificationCenter: unsafe,
        .captureScreenFull: unsafe,
        .captureScreenSelection: ActionKindCapabilities(
          requiresInteractiveSelection: true,
          retryBehavior: .unsafe
        ),
        .captureScreenWindow: ActionKindCapabilities(
          requiresInteractiveSelection: true,
          retryBehavior: .unsafe
        ),
        .windowPlacement: focusedWindow(retryBehavior: .safe),
        .windowMove: focusedWindow(retryBehavior: .unsafe),
      ]
    )
  }

  func testCapabilitiesRoundTripCodable() throws {
    let capabilities = ActionKind.windowPlacement.capabilities
    let data = try JSONEncoder().encode(capabilities)

    XCTAssertEqual(try JSONDecoder().decode(ActionKindCapabilities.self, from: data), capabilities)
  }

  func testCapabilitiesUseCanonicalCodableShape() throws {
    let capabilities = frontmostApplication(
      isDestructive: true,
      retryBehavior: .contextDependent
    )
    let data = try JSONEncoder().encode(capabilities)
    let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(payload?["requiresFrontmostApplication"] as? Bool, true)
    XCTAssertEqual(payload?["requiresFocusedWindow"] as? Bool, false)
    XCTAssertEqual(payload?["requiresInteractiveSelection"] as? Bool, false)
    XCTAssertEqual(payload?["isDestructive"] as? Bool, true)
    XCTAssertEqual(payload?["retryBehavior"] as? String, "context-dependent")
  }

  func testCapabilitiesDecodeCanonicalCodableShape() throws {
    let data = Data(
      """
      {
        "requiresFrontmostApplication": true,
        "requiresFocusedWindow": false,
        "requiresInteractiveSelection": false,
        "isDestructive": true,
        "retryBehavior": "context-dependent"
      }
      """.utf8
    )

    XCTAssertEqual(
      try JSONDecoder().decode(ActionKindCapabilities.self, from: data),
      frontmostApplication(isDestructive: true, retryBehavior: .contextDependent)
    )
  }

  func testCapabilitiesRejectUnknownFieldsWhenDecoding() throws {
    let data = Data(
      """
      {
        "requiresFrontmostApplication": false,
        "requiresFocusedWindow": true,
        "requiresInteractiveSelection": false,
        "isDestructive": false,
        "retryBehavior": "safe",
        "metadata": {}
      }
      """.utf8
    )

    XCTAssertThrowsError(try JSONDecoder().decode(ActionKindCapabilities.self, from: data)) {
      error in
      guard case let DecodingError.dataCorrupted(context) = error else {
        return XCTFail("Expected dataCorrupted, got \(error)")
      }
      XCTAssertEqual(context.codingPath.map(\.stringValue), ["metadata"])
    }
  }

  private var safe: ActionKindCapabilities {
    ActionKindCapabilities(retryBehavior: .safe)
  }

  private var unsafe: ActionKindCapabilities {
    ActionKindCapabilities(retryBehavior: .unsafe)
  }

  private var destructiveUnsafe: ActionKindCapabilities {
    ActionKindCapabilities(isDestructive: true, retryBehavior: .unsafe)
  }

  private func frontmostApplication(
    isDestructive: Bool = false,
    retryBehavior: ActionRetryBehavior
  ) -> ActionKindCapabilities {
    ActionKindCapabilities(
      requiresFrontmostApplication: true,
      isDestructive: isDestructive,
      retryBehavior: retryBehavior
    )
  }

  private func focusedWindow(retryBehavior: ActionRetryBehavior) -> ActionKindCapabilities {
    ActionKindCapabilities(requiresFocusedWindow: true, retryBehavior: retryBehavior)
  }
}

import XCTest

@testable import ActionKit

final class ActionPermissionHintTests: XCTestCase {
  func testPermissionReasonRawValuesAreStable() {
    XCTAssertEqual(
      ActionPermissionReason.allCases.map(\.rawValue),
      [
        "accessibility",
        "accessibility-key-event",
        "accessibility-windowing",
        "automation-apple-events",
        "screen-recording-capture",
      ]
    )
  }

  func testPermissionReasonsRoundTripCodableRawValue() throws {
    for reason in ActionPermissionReason.allCases {
      let data = try JSONEncoder().encode(reason)
      XCTAssertEqual(try JSONDecoder().decode(ActionPermissionReason.self, from: data), reason)
    }
  }

  func testPermissionHintRoundTripsCodableValues() throws {
    let hint = ActionPermissionHint(
      permission: .automation,
      reason: .automationAppleEvents
    )

    let data = try JSONEncoder().encode(hint)
    let decoded = try JSONDecoder().decode(ActionPermissionHint.self, from: data)

    XCTAssertEqual(decoded, hint)
  }

  func testPermissionHintIsHashable() {
    let hints: Set<ActionPermissionHint> = [
      .init(permission: .accessibility, reason: .accessibilityKeyEvent),
      .init(permission: .accessibility, reason: .accessibilityKeyEvent),
      .init(permission: .accessibility, reason: .accessibilityWindowing),
    ]

    XCTAssertEqual(hints.count, 2)
  }

  func testPermissionHintUsesStableCodableShape() throws {
    let hint = ActionPermissionHint(
      permission: .screenRecording,
      reason: .screenRecordingCapture
    )

    let data = try JSONEncoder().encode(hint)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(object?["permission"] as? String, "screen-recording")
    XCTAssertEqual(object?["reason"] as? String, "screen-recording-capture")
  }
}

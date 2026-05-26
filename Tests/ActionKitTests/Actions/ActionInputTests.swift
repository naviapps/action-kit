import WindowKit
import XCTest

@testable import ActionKit

final class ActionInputTests: XCTestCase {
  func testNormalizedStringTrimsWhitespaceAndNewlines() {
    XCTAssertEqual(ActionInput.normalizedString("  https://example.com\n"), "https://example.com")
  }

  func testNormalizedStringRejectsBlankValues() {
    XCTAssertNil(ActionInput.normalizedString(" \n\t "))
  }

  func testInputShapeMatchesPayload() {
    XCTAssertEqual(ActionInput.string("value").shape, .string)
    XCTAssertEqual(ActionInput.windowPlacement(.init(placement: .leftHalf)).shape, .windowPlacement)
    XCTAssertEqual(ActionInput.windowMove(.init(direction: .next)).shape, .windowMove)
  }

  func testInputNormalizationMatchesPayloadRules() {
    XCTAssertEqual(ActionInput.string("  value\n").normalized, .string("value"))
    XCTAssertNil(ActionInput.string(" \n\t ").normalized)
    XCTAssertEqual(
      ActionInput.windowPlacement(.init(placement: .leftHalf)).normalized,
      .windowPlacement(.init(placement: .leftHalf))
    )
    XCTAssertEqual(
      ActionInput.windowMove(.init(direction: .next)).normalized,
      .windowMove(.init(direction: .next))
    )
  }

  func testInputIsHashable() {
    let placement = WindowPlacementRequest(placement: .leftHalf)
    let inputs: Set<ActionInput> = [
      .string("https://example.com"),
      .windowPlacement(placement),
      .windowPlacement(placement),
      .windowMove(.init(direction: .next)),
    ]

    XCTAssertEqual(inputs.count, 3)
  }
}

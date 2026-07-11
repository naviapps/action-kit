import XCTest

import ActionKit

final class ActionInputTests: XCTestCase {
  func testInputShapeMatchesPayload() {
    XCTAssertEqual(ActionInput.string("value").shape, .string)
    XCTAssertEqual(
      ActionInput.windowPlacement(
        .init(placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))
      ).shape, .windowPlacement)
    XCTAssertEqual(ActionInput.windowMove(.init(direction: .next)).shape, .windowMove)
  }

  func testInputIsHashable() {
    let placement = WindowPlacementRequest(
      placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))
    let inputs: Set<ActionInput> = [
      .string("https://example.com"),
      .windowPlacement(placement),
      .windowPlacement(placement),
      .windowMove(.init(direction: .next)),
    ]

    XCTAssertEqual(inputs.count, 3)
  }
}

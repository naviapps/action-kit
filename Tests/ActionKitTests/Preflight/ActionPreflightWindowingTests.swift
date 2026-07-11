import XCTest

import ActionKit

final class ActionPreflightWindowingTests: XCTestCase {
  func testExplicitWindowPlacementRequestsArePreserved() {
    let cases: [(action: Action, request: WindowPlacementRequest)] = [
      (.windowPlacement(.init(placement: .fill)), .init(placement: .fill)),
      (
        .windowPlacement(
          .init(
            placement: .grid(
              columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))),
        .init(placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))
      ),
      (
        .windowPlacement(
          .init(
            placement: .grid(
              columns: 2, rows: 1, column: 1, row: 0, columnSpan: 1, rowSpan: 1))),
        .init(placement: .grid(columns: 2, rows: 1, column: 1, row: 0, columnSpan: 1, rowSpan: 1))
      ),
      (
        .windowPlacement(
          .init(
            placement: .grid(
              columns: 1, rows: 2, column: 0, row: 1, columnSpan: 1, rowSpan: 1))),
        .init(placement: .grid(columns: 1, rows: 2, column: 0, row: 1, columnSpan: 1, rowSpan: 1))
      ),
      (
        .windowPlacement(
          .init(
            placement: .grid(
              columns: 1, rows: 2, column: 0, row: 0, columnSpan: 1, rowSpan: 1))),
        .init(placement: .grid(columns: 1, rows: 2, column: 0, row: 0, columnSpan: 1, rowSpan: 1))
      ),
      (
        .windowPlacement(.init(placement: .centered(widthRatio: 0.85, heightRatio: 0.85))),
        .init(placement: .centered(widthRatio: 0.85, heightRatio: 0.85))
      ),
    ]

    for expectation in cases {
      guard
        case .placeFocusedWindow(let request) = assertWindowingExecution(for: expectation.action)
      else {
        return XCTFail("Expected placement execution for \(expectation.action)")
      }

      XCTAssertEqual(request, expectation.request)
    }
  }

  func testExplicitWindowMoveRequestsArePreserved() {
    let cases: [(action: Action, request: WindowMoveRequest)] = [
      (.windowMove(.init(direction: .next)), .init(direction: .next)),
      (.windowMove(.init(direction: .previous)), .init(direction: .previous)),
    ]

    for expectation in cases {
      guard
        case .moveFocusedWindow(let request) = assertWindowingExecution(for: expectation.action)
      else {
        return XCTFail("Expected move execution for \(expectation.action)")
      }

      XCTAssertEqual(request, expectation.request)
    }
  }

  func testWindowingRequestsPreserveScreenAndAreaOptions() {
    let placement = WindowPlacementRequest(
      placement: .grid(columns: 2, rows: 2, column: 1, row: 0, columnSpan: 1, rowSpan: 2),
      screen: .orderedIndex(1),
      area: .full,
      inset: 8
    )
    let move = WindowMoveRequest(direction: .previous, preservesRelativePosition: false)

    XCTAssertEqual(
      assertWindowingExecution(for: .windowPlacement(placement)),
      .placeFocusedWindow(placement)
    )
    XCTAssertEqual(assertWindowingExecution(for: .windowMove(move)), .moveFocusedWindow(move))
  }

  private func assertWindowingExecution(
    for action: Action,
    file: StaticString = #filePath,
    line: UInt = #line
  ) -> WindowingExecution? {
    let plan = ActionPreflight.plan(for: action)

    XCTAssertEqual(plan.steps.count, 1, file: file, line: line)
    XCTAssertEqual(
      plan.permissionRequirements,
      .init(primary: [.accessibility], fallback: []),
      file: file,
      line: line
    )

    guard case .windowing(let execution) = plan.steps.first?.method else {
      XCTFail("Expected windowing execution for \(action)", file: file, line: line)
      return nil
    }

    return execution
  }
}

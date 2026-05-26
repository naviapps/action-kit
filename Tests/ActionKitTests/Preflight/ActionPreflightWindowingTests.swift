import XCTest

@testable import ActionKit

final class ActionPreflightWindowingTests: XCTestCase {
  func testWindowPlacementShortcutsUseExpectedRequests() {
    let cases: [(action: Action, request: WindowPlacementRequest)] = [
      (.windowMaximize, .init(placement: .fill)),
      (.windowLeftHalf, .init(placement: .leftHalf)),
      (.windowRightHalf, .init(placement: .rightHalf)),
      (.windowTopHalf, .init(placement: .topHalf)),
      (.windowBottomHalf, .init(placement: .bottomHalf)),
      (.windowCenter, .init(placement: .centered(widthRatio: 0.85, heightRatio: 0.85))),
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

  func testWindowMoveShortcutsUseExpectedRequests() {
    let cases: [(action: Action, request: WindowMoveRequest)] = [
      (.windowMoveToNextScreen, .init(direction: .next)),
      (.windowMoveToPreviousScreen, .init(direction: .previous)),
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

  func testExplicitWindowingRequestsArePreserved() {
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

  func testWindowingPlanDoesNotHandleOtherActions() {
    XCTAssertNil(ActionPreflight.windowingPlan(for: .copy))
    XCTAssertNil(ActionPreflight.windowingPlan(for: .openURL("https://example.com")))
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

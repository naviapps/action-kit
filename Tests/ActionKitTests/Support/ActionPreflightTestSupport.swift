import XCTest

import ActionKit

struct KeyEventPlanExpectation {
  let action: Action
  let virtualKeyCode: UInt16
  let modifiers: ActionModifiers

  init(action: Action, virtualKeyCode: UInt16, modifiers: ActionModifiers = []) {
    self.action = action
    self.virtualKeyCode = virtualKeyCode
    self.modifiers = modifiers
  }
}

extension XCTestCase {
  func assertSingleAccessibilityKeyEventPlan(
    _ expectation: KeyEventPlanExpectation,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let plan = ActionPreflight.plan(for: expectation.action)

    XCTAssertEqual(plan.steps.count, 1, file: file, line: line)
    XCTAssertEqual(
      plan.permissionRequirements,
      .init(primary: [.accessibility], fallback: []),
      file: file,
      line: line
    )
    assertKeyEventStep(
      plan.steps.first,
      matches: expectation,
      requiredPermissions: [.accessibility],
      file: file,
      line: line
    )
  }

  func assertKeyEventStep(
    _ step: ActionStep?,
    matches expectation: KeyEventPlanExpectation,
    isFallback: Bool = false,
    requiredPermissions: Set<ActionPermission>,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    guard let step else {
      return XCTFail("Expected keyEvent step for \(expectation.action)", file: file, line: line)
    }

    guard case .keyEvent(let event) = step.method else {
      return XCTFail("Expected keyEvent for \(expectation.action)", file: file, line: line)
    }

    XCTAssertEqual(step.isFallback, isFallback, file: file, line: line)
    XCTAssertEqual(step.requiredPermissions, requiredPermissions, file: file, line: line)
    XCTAssertEqual(event.virtualKeyCode, expectation.virtualKeyCode, file: file, line: line)
    XCTAssertEqual(event.modifiers, expectation.modifiers, file: file, line: line)
  }
}

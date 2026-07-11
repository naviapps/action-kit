import XCTest

import ActionKit

final class ActionPreflightEditingTests: XCTestCase {
  func testEditingActionsUseExpectedKeyEvents() {
    let cases: [KeyEventPlanExpectation] = [
      .init(action: .copy, virtualKeyCode: 8, modifiers: [.command]),
      .init(action: .paste, virtualKeyCode: 9, modifiers: [.command]),
      .init(action: .cut, virtualKeyCode: 7, modifiers: [.command]),
      .init(action: .undo, virtualKeyCode: 6, modifiers: [.command]),
      .init(action: .redo, virtualKeyCode: 6, modifiers: [.command, .shift]),
    ]

    for expectation in cases {
      assertSingleAccessibilityKeyEventPlan(expectation)
    }
  }
}

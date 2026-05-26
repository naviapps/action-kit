import XCTest

@testable import ActionKit

final class ActionPreflightKeyboardTests: XCTestCase {
  func testKeyboardShortcutUsesKeyboardPlan() {
    let plan = ActionPreflight.plan(for: .keyboardShortcut("cmd+shift+p"))
    XCTAssertEqual(plan.steps.count, 1)
    XCTAssertEqual(plan.steps.first?.requiredPermissions, [.accessibility])
    XCTAssertEqual(plan.permissionRequirements, .init(primary: [.accessibility], fallback: []))

    guard case .keyEventFromKeyboardShortcut(let value) = plan.steps.first?.method else {
      return XCTFail("Expected keyboard shortcut step")
    }

    XCTAssertEqual(value, "cmd+shift+p")
  }

  func testKeyboardPlanPreservesShortcutStringForExecutorParsing() {
    let plan = ActionPreflight.plan(for: .keyboardShortcut("  cmd+shift+p  "))

    guard case .keyEventFromKeyboardShortcut(let value) = plan.steps.first?.method else {
      return XCTFail("Expected keyboard shortcut step")
    }

    XCTAssertEqual(value, "  cmd+shift+p  ")
  }

  func testKeyboardPlanDoesNotHandleOtherActions() {
    XCTAssertNil(ActionPreflight.keyboardPlan(for: .copy))
    XCTAssertNil(ActionPreflight.keyboardPlan(for: .openURL("https://example.com")))
  }
}

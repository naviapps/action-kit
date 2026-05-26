import XCTest

@testable import ActionKit

final class ActionPreflightWorkspaceTests: XCTestCase {
  func testWorkspaceActionsUseExpectedExecutionMethods() {
    let cases: [(action: Action, method: ActionMethod)] = [
      (.openURL("https://example.com"), .openURL("https://example.com")),
      (.openFolder("/tmp"), .openFolder("/tmp")),
      (.launchApplication("com.example.App"), .launchApplication("com.example.App")),
      (.runShortcut("Daily"), .runShortcut("Daily")),
    ]

    for expectation in cases {
      assertWorkspaceMethod(for: expectation.action, equals: expectation.method)
    }
  }

  func testWorkspacePlanPreservesHostValuesForExecutorValidation() {
    let cases: [(action: Action, method: ActionMethod)] = [
      (.openURL("  https://example.com  "), .openURL("  https://example.com  ")),
      (.openFolder("  /tmp  "), .openFolder("  /tmp  ")),
      (.launchApplication("  com.example.App  "), .launchApplication("  com.example.App  ")),
      (.runShortcut("  Daily  "), .runShortcut("  Daily  ")),
    ]

    for expectation in cases {
      assertWorkspaceMethod(for: expectation.action, equals: expectation.method)
    }
  }

  func testWorkspacePlanDoesNotHandleOtherActions() {
    XCTAssertNil(ActionPreflight.workspacePlan(for: .copy))
    XCTAssertNil(ActionPreflight.workspacePlan(for: .hideFrontmostApplication))
    XCTAssertNil(ActionPreflight.workspacePlan(for: .keyboardShortcut("cmd+c")))
  }

  private func assertWorkspaceMethod(
    for action: Action,
    equals method: ActionMethod,
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    let plan = ActionPreflight.plan(for: action)

    XCTAssertEqual(plan.steps.count, 1, file: file, line: line)
    XCTAssertEqual(plan.steps.first?.method, method, file: file, line: line)
    XCTAssertEqual(
      plan.permissionRequirements,
      .init(primary: [], fallback: []),
      file: file,
      line: line
    )
  }
}

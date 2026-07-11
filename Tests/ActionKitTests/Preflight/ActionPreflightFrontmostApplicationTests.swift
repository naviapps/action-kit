import XCTest

import ActionKit

final class ActionPreflightFrontmostApplicationTests: XCTestCase {
  func testFrontmostApplicationActionsUseFrontmostApplicationMethods() {
    let cases: [(Action, ActionMethod)] = [
      (.hideFrontmostApplication, .hideFrontmostApplication),
      (.quitFrontmostApplication, .terminateFrontmostApplication),
    ]

    for (action, method) in cases {
      let plan = ActionPreflight.plan(for: action)
      XCTAssertEqual(plan.steps.count, 1)
      XCTAssertEqual(plan.steps.first?.method, method)
      XCTAssertEqual(plan.steps.first?.requiredPermissions, [])
      XCTAssertEqual(plan.permissionRequirements, .init(primary: [], fallback: []))
    }
  }
}

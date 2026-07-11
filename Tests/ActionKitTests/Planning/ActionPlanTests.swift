import XCTest

import ActionKit

final class ActionPlanTests: XCTestCase {
  func testEmptyPlanHasNoPermissionRequirements() {
    let plan = ActionPlan(steps: [])

    XCTAssertTrue(plan.permissionRequirements.isEmpty)
    XCTAssertEqual(plan.permissionRequirements.primary, [])
    XCTAssertEqual(plan.permissionRequirements.fallback, [])
  }

  func testPermissionRequirementsAggregation() {
    let primaryStep = ActionStep(
      method: .appleScript(
        source: "tell app",
        launchesSystemEvents: true,
        usesAccessibility: true
      ),
      isFallback: false
    )
    let fallbackStep = ActionStep(
      method: .screenCapture(arguments: ["-x"]),
      isFallback: true
    )
    let plan = ActionPlan(steps: [primaryStep, fallbackStep])
    let requirements = plan.permissionRequirements

    XCTAssertEqual(requirements.primary, [.automation, .accessibility])
    XCTAssertEqual(requirements.fallback, [.screenRecording])
    XCTAssertEqual(requirements.fallbackOnly, [.screenRecording])
    XCTAssertEqual(requirements.all, [.automation, .accessibility, .screenRecording])
  }
}

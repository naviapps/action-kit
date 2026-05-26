import XCTest

@testable import ActionKit

final class ActionPlanTests: XCTestCase {
  func testEmptyPlanHasNoPermissionRequirements() {
    let plan = ActionPlan(steps: [])

    XCTAssertTrue(plan.permissionRequirements.isEmpty)
    XCTAssertEqual(plan.permissionRequirements.primary, [])
    XCTAssertEqual(plan.permissionRequirements.fallback, [])
  }

  func testPermissionRequirementsAggregation() {
    let primaryStep = ActionStep(
      method: .openURL("https://example.com"),
      requiredPermissions: [.automation, .accessibility],
      isFallback: false
    )
    let fallbackStep = ActionStep(
      method: .openURL("https://example.com"),
      requiredPermissions: [.automation, .screenRecording],
      isFallback: true
    )
    let plan = ActionPlan(steps: [primaryStep, fallbackStep])
    let requirements = plan.permissionRequirements

    XCTAssertEqual(requirements.primary, [.automation, .accessibility])
    XCTAssertEqual(requirements.fallback, [.automation, .screenRecording])
    XCTAssertEqual(requirements.fallbackOnly, [.screenRecording])
    XCTAssertEqual(requirements.all, [.automation, .accessibility, .screenRecording])
  }
}

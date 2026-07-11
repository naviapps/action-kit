import XCTest

import ActionKit
import ActionKitAppKit

final class ActionExecutorFrontmostApplicationTests: XCTestCase {
  func testHideFrontmostReturnsSkippedWhenNoApp() async {
    let dependencies = makeActionExecutorDependencies(
      frontmostApplicationController: TestFrontmostApplicationController(
        hideResult: .noFrontmostApplication)
    )
    let executor = ActionExecutor(configuration: .init(), dependencies: dependencies)
    let plan = ActionPlan(steps: [.init(method: .hideFrontmostApplication)])

    let outcome = await executor.execute(plan: plan)
    XCTAssertEqual(outcome.finalResult, .skipped(.noFrontmostApplication))
  }

  func testHideFrontmostReturnsInternalErrorWhenCommandFails() async {
    let logs = LogRecorder()
    let dependencies = makeActionExecutorDependencies(
      frontmostApplicationController: TestFrontmostApplicationController(hideResult: .failed)
    )
    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [.init(method: .hideFrontmostApplication)])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .internalError)
    XCTAssertEqual(error.diagnosticMessage, "Failed to hide frontmost application")
    XCTAssertTrue(logs.contains(level: .error, message: "Failed to hide frontmost application"))
  }

  func testHideFrontmostReturnsSuccessWhenAppHidden() async {
    let dependencies = makeActionExecutorDependencies(
      frontmostApplicationController: TestFrontmostApplicationController()
    )
    let executor = ActionExecutor(configuration: .init(), dependencies: dependencies)

    let plan = ActionPlan(steps: [.init(method: .hideFrontmostApplication)])
    let outcome = await executor.execute(plan: plan)
    XCTAssertEqual(outcome.finalResult, ActionResult.success)
  }

  func testTerminateFrontmostReturnsSkippedWhenNoApp() async {
    let dependencies = makeActionExecutorDependencies(
      frontmostApplicationController: TestFrontmostApplicationController(
        terminateResult: .noFrontmostApplication)
    )
    let executor = ActionExecutor(configuration: .init(), dependencies: dependencies)

    let plan = ActionPlan(steps: [.init(method: .terminateFrontmostApplication)])
    let outcome = await executor.execute(plan: plan)
    XCTAssertEqual(outcome.finalResult, ActionResult.skipped(.noFrontmostApplication))
  }

  func testTerminateFrontmostReturnsInternalErrorWhenCommandFails() async {
    let logs = LogRecorder()
    let dependencies = makeActionExecutorDependencies(
      frontmostApplicationController: TestFrontmostApplicationController(
        terminateResult: .failed
      )
    )
    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: dependencies
    )

    let plan = ActionPlan(steps: [.init(method: .terminateFrontmostApplication)])
    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .internalError)
    XCTAssertEqual(error.diagnosticMessage, "Failed to terminate frontmost application")
    XCTAssertTrue(
      logs.contains(level: .error, message: "Failed to terminate frontmost application")
    )
  }

  func testTerminateFrontmostReturnsSuccessWhenAppTerminated() async {
    let dependencies = makeActionExecutorDependencies(
      frontmostApplicationController: TestFrontmostApplicationController()
    )
    let executor = ActionExecutor(configuration: .init(), dependencies: dependencies)

    let plan = ActionPlan(steps: [.init(method: .terminateFrontmostApplication)])
    let outcome = await executor.execute(plan: plan)
    XCTAssertEqual(outcome.finalResult, ActionResult.success)
  }
}

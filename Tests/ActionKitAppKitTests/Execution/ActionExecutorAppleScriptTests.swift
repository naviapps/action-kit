import ApplicationServices
import XCTest

@testable import ActionKit
@testable import ActionKitAppKit

final class ActionExecutorAppleScriptTests: XCTestCase {
  func testAutomationDeniedTriggersCallback() async {
    let recorder = AutomationDeniedRecorder()
    let denied = Int(errAEEventNotPermitted)
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(.init(appleScriptErrorNumber: denied)))
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(
          ensureAutomation: { true },
          onAutomationDenied: { appleScriptErrorNumber in
            await recorder.record(appleScriptErrorNumber: appleScriptErrorNumber)
          })
      ),
      dependencies: dependencies
    )

    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false))
    ])
    let outcome = await executor.execute(plan: plan)

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, ActionErrorCode.permissionDenied)
    XCTAssertEqual(error.permission, ActionPermission.automation)
    let recorded = await recorder.appleScriptErrorNumber
    XCTAssertEqual(recorded, denied)
  }

  func testAutomationDeniedDoesNotTriggerWhenLastErrorIsAccessibility() async {
    let recorder = AutomationDeniedRecorder()
    let denied = Int(errAEEventNotPermitted)
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(.init(appleScriptErrorNumber: denied)))
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(
          ensureAccessibility: { false },
          ensureAutomation: { true },
          onAutomationDenied: { appleScriptErrorNumber in
            await recorder.record(appleScriptErrorNumber: appleScriptErrorNumber)
          })
      ),
      dependencies: dependencies
    )

    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false)),
      .init(method: .keyEventFromKeyboardShortcut("cmd+a")),
    ])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, ActionErrorCode.permissionDenied)
    XCTAssertEqual(error.permission, ActionPermission.accessibility)
    let recorded = await recorder.appleScriptErrorNumber
    XCTAssertNil(recorded)
  }

  func testAppleScriptRequiresSystemEventsLaunches() async {
    let launcher = TestSystemEventsLauncher()
    let appleScriptExecutor = RecordingAppleScriptExecutor()
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: appleScriptExecutor,
      systemEventsLauncher: launcher
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(
          ensureAccessibility: { true },
          ensureAutomation: { true }
        )
      ),
      dependencies: dependencies
    )

    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: true))
    ])
    let outcome = await executor.execute(plan: plan)

    XCTAssertEqual(outcome.finalResult, ActionResult.success)
    let count = await launcher.invocationCount
    XCTAssertEqual(count, 1)
    XCTAssertEqual(appleScriptExecutor.invocationCount, 1)
    XCTAssertEqual(appleScriptExecutor.sources, ["tell app"])
  }

  func testAccessibilityCheckerFailureDoesNotLaunchSystemEvents() async {
    let launcher = TestSystemEventsLauncher()
    let appleScriptExecutor = RecordingAppleScriptExecutor()
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: appleScriptExecutor,
      systemEventsLauncher: launcher
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(
          ensureAccessibility: { false },
          ensureAutomation: { true }
        )
      ),
      dependencies: dependencies
    )

    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: true))
    ])
    let outcome = await executor.execute(plan: plan)

    XCTAssertEqual(outcome.finalResult, .failure(.permissionDenied(.accessibility)))
    let count = await launcher.invocationCount
    XCTAssertEqual(count, 0)
    XCTAssertEqual(appleScriptExecutor.invocationCount, 0)
  }

  func testAutomationCheckerFailureDoesNotLaunchSystemEvents() async {
    let launcher = TestSystemEventsLauncher()
    let appleScriptExecutor = RecordingAppleScriptExecutor()
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: appleScriptExecutor,
      systemEventsLauncher: launcher
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { false })
      ),
      dependencies: dependencies
    )

    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: true))
    ])
    let outcome = await executor.execute(plan: plan)

    XCTAssertEqual(outcome.finalResult, .failure(.permissionDenied(.automation)))
    let count = await launcher.invocationCount
    XCTAssertEqual(count, 0)
    XCTAssertEqual(appleScriptExecutor.invocationCount, 0)
  }

  func testSystemEventsLaunchFailureReturnsInternalErrorBeforeAppleScriptExecution() async {
    let launcher = TestSystemEventsLauncher(result: false)
    let appleScriptExecutor = RecordingAppleScriptExecutor()
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: appleScriptExecutor,
      systemEventsLauncher: launcher
    )
    let logs = LogRecorder()
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(
          ensureAccessibility: { true },
          ensureAutomation: { true }
        ),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: dependencies
    )

    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: true))
    ])
    let outcome = await executor.execute(plan: plan)

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, ActionErrorCode.internalError)
    XCTAssertTrue(error.diagnosticMessage.contains("System Events is not running"))
    XCTAssertTrue(logs.contains(level: .error, message: "System Events is not running"))
    let count = await launcher.invocationCount
    XCTAssertEqual(count, 1)
    XCTAssertEqual(appleScriptExecutor.invocationCount, 0)
  }

  func testAppleScriptProcessNotFoundMapsToAppleScriptFailed() async {
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(.init(appleScriptErrorNumber: -600)))
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { true })
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false))
    ])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .appleScriptFailed)
    XCTAssertNil(error.permission)
    XCTAssertEqual(error.appleScriptErrorNumber, -600)
  }

  func testAppleScriptEventNotPermittedMapsToPermissionDenied() async {
    let logs = LogRecorder()
    let denied = Int(errAEEventNotPermitted)
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(.init(appleScriptErrorNumber: denied)))
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { true }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false))
    ])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .permissionDenied)
    XCTAssertEqual(error.permission, .automation)
    XCTAssertEqual(error.appleScriptErrorNumber, denied)
    XCTAssertTrue(
      logs.contains(
        level: .error,
        message: "Permission denied: automation (AppleScript error number \(denied))"
      )
    )
  }

  func testAppleScriptErrorMapsToAppleScriptFailed() async {
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(.init(appleScriptErrorNumber: 42)))
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { true })
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false))
    ])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .appleScriptFailed)
    XCTAssertEqual(error.appleScriptErrorNumber, 42)
    XCTAssertFalse(error.diagnosticMessage.contains("bad"))
    XCTAssertTrue(error.diagnosticMessage.contains("42"))
  }

  func testAppleScriptErrorUsesFailureMessage() async {
    let logs = LogRecorder()
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(
          .init(
            appleScriptErrorNumber: 42,
            message: "The variable bad is not defined."
          )
        )
      )
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { true }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false))
    ])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .appleScriptFailed)
    XCTAssertEqual(error.appleScriptErrorNumber, 42)
    XCTAssertTrue(error.diagnosticMessage.contains("The variable bad is not defined."))
    XCTAssertTrue(error.diagnosticMessage.contains("42"))
    XCTAssertTrue(
      logs.contains(
        level: .error,
        message: "The variable bad is not defined. (AppleScript error number 42)"
      )
    )
  }

  func testAppleScriptErrorUsesFailureMessageWithoutNumber() async {
    let logs = LogRecorder()
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(
          .init(
            appleScriptErrorNumber: nil,
            message: "The variable bad is not defined."
          )
        )
      )
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { true }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false))
    ])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .appleScriptFailed)
    XCTAssertNil(error.appleScriptErrorNumber)
    XCTAssertEqual(error.diagnosticMessage, "The variable bad is not defined.")
    XCTAssertTrue(logs.contains(level: .error, message: "The variable bad is not defined."))
  }

  func testAppleScriptErrorWithoutNumberMapsToAppleScriptFailed() async {
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(.init(appleScriptErrorNumber: nil)))
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { true })
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false))
    ])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .appleScriptFailed)
    XCTAssertNil(error.appleScriptErrorNumber)
    XCTAssertEqual(error.diagnosticMessage, "AppleScript execution failed")
  }

  func testAppleScriptErrorIgnoresBlankFailureMessage() async {
    let logs = LogRecorder()
    let dependencies = makeActionExecutorDependencies(
      appleScriptExecutor: TestAppleScriptExecutor(
        result: .failure(
          .init(
            appleScriptErrorNumber: 42,
            message: " \n "
          )
        )
      )
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { true }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [
      .init(method: .appleScript(source: "tell app", requiresSystemEvents: false))
    ])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .appleScriptFailed)
    XCTAssertEqual(error.appleScriptErrorNumber, 42)
    XCTAssertEqual(
      error.diagnosticMessage,
      "AppleScript execution failed with AppleScript error number 42"
    )
    XCTAssertTrue(
      logs.contains(
        level: .error,
        message: "AppleScript execution failed with AppleScript error number 42"
      )
    )
  }

  func testAppleScriptReturnsAutomationPermissionDeniedWhenCheckerFails() async {
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAutomation: { false })
      )
    )

    let outcome = await executor.execute(.toggleAppearance)
    XCTAssertEqual(outcome.finalResult, .failure(.permissionDenied(.automation)))
    XCTAssertEqual(outcome.attempts.count, 1)
    XCTAssertEqual(outcome.attempts.first?.result, .failure(.permissionDenied(.automation)))
  }
}

private final class RecordingAppleScriptExecutor: AppleScriptExecuting, @unchecked Sendable {
  private let lock = NSLock()
  private var count = 0
  private var recordedSources: [String] = []

  func execute(source: String) async -> Result<Void, AppleScriptExecutionFailure> {
    lock.withLock {
      count += 1
      recordedSources.append(source)
    }
    return .success(())
  }

  var invocationCount: Int {
    lock.withLock {
      count
    }
  }

  var sources: [String] {
    lock.withLock {
      recordedSources
    }
  }
}

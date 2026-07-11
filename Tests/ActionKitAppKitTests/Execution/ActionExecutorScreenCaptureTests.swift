import XCTest

import ActionKit
import ActionKitAppKit

final class ActionExecutorScreenCaptureTests: XCTestCase {
  func testScreenCaptureCallsRecoveryHookWhenAccessCheckFails() async {
    let logs = LogRecorder()
    let tracker = ScreenRecordingTracker()
    let processRunner = TestScreenCaptureProcessRunner()
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(
          onScreenRecordingRequired: {
            await tracker.markRequested()
          }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: makeActionExecutorDependencies(
        screenCaptureProcessRunner: processRunner,
        screenCaptureAccessChecker: TestScreenCaptureAccessChecker(result: false)
      )
    )

    let outcome = await executor.execute(.captureScreenFull)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .permissionDenied)
    XCTAssertEqual(error.permission, .screenRecording)
    let requested = await tracker.wasRequested
    XCTAssertTrue(requested)
    XCTAssertTrue(processRunner.receivedArguments.isEmpty)
    XCTAssertTrue(logs.contains(level: .warning, message: "Permission denied: screen-recording"))
  }

  func testScreenCapturePassesPlannedArgumentsToRunner() async {
    let expectations: [(action: Action, arguments: [String])] = [
      (.captureScreenFull, ["-x"]),
      (.captureScreenSelection, ["-i"]),
      (.captureScreenWindow, ["-i", "-W"]),
    ]

    for expectation in expectations {
      let processRunner = TestScreenCaptureProcessRunner()
      let executor = ActionExecutor(
        configuration: .init(),
        dependencies: makeActionExecutorDependencies(screenCaptureProcessRunner: processRunner)
      )

      let outcome = await executor.execute(expectation.action)

      XCTAssertEqual(outcome.finalResult, .success)
      XCTAssertEqual(processRunner.receivedArguments, [expectation.arguments])
    }
  }

  func testScreenCaptureProcessFailureReturnsScreenCaptureFailed() async {
    let logs = LogRecorder()
    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: makeActionExecutorDependencies(
        screenCaptureProcessRunner: TestScreenCaptureProcessRunner(
          result: .failure(.init(terminationStatus: 2))
        )
      )
    )

    let outcome = await executor.execute(.captureScreenFull)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .screenCaptureFailed)
    XCTAssertEqual(error.diagnosticMessage, "Screen capture failed with termination status 2")
    XCTAssertTrue(
      logs.contains(level: .error, message: "Screen capture failed with termination status 2")
    )
  }

  func testScreenCaptureProcessFailureWithoutStatusReturnsScreenCaptureFailed() async {
    let logs = LogRecorder()
    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: makeActionExecutorDependencies(
        screenCaptureProcessRunner: TestScreenCaptureProcessRunner(
          result: .failure(.init(terminationStatus: nil))
        )
      )
    )

    let outcome = await executor.execute(.captureScreenFull)
    XCTAssertEqual(outcome.finalResult, .failure(.screenCaptureFailed("Screen capture failed")))
    XCTAssertTrue(logs.contains(level: .error, message: "Screen capture failed"))
  }
}

private actor ScreenRecordingTracker {
  private(set) var requested = false

  func markRequested() {
    requested = true
  }

  var wasRequested: Bool {
    requested
  }
}

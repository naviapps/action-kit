import ApplicationServices
import WindowKit
import WindowKitAppKit
import XCTest

@testable import ActionKit
@testable import ActionKitAppKit

final class ActionExecutorWindowingTests: XCTestCase {
  func testWindowingExecutionReturnsPermissionDeniedWhenAccessibilityUnavailable() async {
    let factoryInvocations = InvocationRecorder()
    let executor = ActionExecutor(
      configuration: .init(
        permissions: .init(ensureAccessibility: { false })
      ),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: {
        factoryInvocations.record()
        return TestFocusedWindowController()
      })
    )
    let plan = ActionPlan(steps: [
      .init(method: .windowing(.moveFocusedWindow(.init(direction: .next))))
    ])

    let outcome = await executor.execute(plan: plan)

    XCTAssertEqual(outcome.finalResult, .failure(.permissionDenied(.accessibility)))
    XCTAssertEqual(factoryInvocations.invocationCount, 0)
  }

  func testWindowPlacementSucceedsWhenControllerAcceptsRequest() async {
    let recorder = TestFocusedWindowController()
    let executor = ActionExecutor(
      configuration: .init(permissions: .init(ensureAccessibility: { true })),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )
    let request = WindowPlacementRequest(
      placement: .leftTwoThirds,
      screen: .orderedIndex(2),
      area: .full,
      inset: 16
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.placeFocusedWindow(request)))
      ]))

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(recorder.recordedPlacement, request)
  }

  func testWindowMoveSucceedsWhenControllerAcceptsRequest() async {
    let recorder = TestFocusedWindowController()
    let executor = ActionExecutor(
      configuration: .init(permissions: .init(ensureAccessibility: { true })),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )
    let request = WindowMoveRequest(direction: .previous, preservesRelativePosition: false)

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.moveFocusedWindow(request)))
      ]))

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(recorder.recordedMove, request)
  }

  func testWindowingExecutionReturnsPermissionDeniedWhenWindowKitReportsAccessibilityUnavailable()
    async
  {
    let recorder = TestFocusedWindowController(placeError: AXWindowError.accessibilityNotTrusted)
    let executor = ActionExecutor(
      configuration: .init(permissions: .init(ensureAccessibility: { true })),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.placeFocusedWindow(.init(placement: .fill))))
      ]))

    XCTAssertEqual(outcome.finalResult, .failure(.permissionDenied(.accessibility)))
  }

  func testWindowMoveSkipsWhenNoFocusedWindowExists() async {
    let recorder = TestFocusedWindowController(moveError: AXWindowError.windowNotFound(.focused))
    let executor = ActionExecutor(
      configuration: .init(permissions: .init(ensureAccessibility: { true })),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(
          method: .windowing(
            .moveFocusedWindow(.init(direction: .previous, preservesRelativePosition: false))))
      ]))

    XCTAssertEqual(outcome.finalResult, .skipped(.noFocusedWindow))
  }

  func testWindowPlacementSkipsWhenFocusedApplicationCannotBeResolved() async {
    let recorder = TestFocusedWindowController(
      placeError: AXWindowError.applicationNotFound(.focused)
    )
    let executor = ActionExecutor(
      configuration: .init(permissions: .init(ensureAccessibility: { true })),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.placeFocusedWindow(.init(placement: .fill))))
      ]))

    XCTAssertEqual(outcome.finalResult, .skipped(.noFocusedWindow))
  }

  func testWindowPlacementMapsInvalidAXValueToInternalError() async {
    let logs = LogRecorder()
    let recorder = TestFocusedWindowController(placeError: AXWindowError.invalidAXValue)
    let executor = ActionExecutor(
      configuration: .init(
        permissions: .init(ensureAccessibility: { true }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.placeFocusedWindow(.init(placement: .fill))))
      ]))

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .internalError)
    XCTAssertTrue(error.diagnosticMessage.contains("Focused-window action failed"))
    XCTAssertTrue(error.diagnosticMessage.contains("invalid Accessibility window value"))
    XCTAssertTrue(
      logs.contains(
        level: .error,
        message: "Focused-window action failed: invalid Accessibility window value"
      )
    )
  }

  func testWindowPlacementIncludesUnsupportedActionInDiagnosticMessage() async {
    let recorder = TestFocusedWindowController(
      placeError: AXWindowError.unsupportedAction("AXRaise")
    )
    let executor = ActionExecutor(
      configuration: .init(permissions: .init(ensureAccessibility: { true })),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.placeFocusedWindow(.init(placement: .fill))))
      ]))

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .internalError)
    XCTAssertTrue(error.diagnosticMessage.contains("unsupported Accessibility window action"))
    XCTAssertTrue(error.diagnosticMessage.contains("AXRaise"))
  }

  func testWindowPlacementIncludesUnderlyingAccessibilityErrorInDiagnosticMessage() async {
    let recorder = TestFocusedWindowController(
      placeError: AXWindowError.underlyingAccessibilityError(.cannotComplete)
    )
    let executor = ActionExecutor(
      configuration: .init(permissions: .init(ensureAccessibility: { true })),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.placeFocusedWindow(.init(placement: .fill))))
      ]))

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .internalError)
    XCTAssertTrue(error.diagnosticMessage.contains("Accessibility window operation failed"))
    XCTAssertTrue(error.diagnosticMessage.contains("AXError"))
  }

  func testWindowPlacementMapsUnexpectedErrorsToInternalError() async {
    let logs = LogRecorder()
    let recorder = TestFocusedWindowController(placeError: UnexpectedWindowingError())
    let executor = ActionExecutor(
      configuration: .init(
        permissions: .init(ensureAccessibility: { true }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.placeFocusedWindow(.init(placement: .fill))))
      ]))

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .internalError)
    XCTAssertTrue(error.diagnosticMessage.contains("Focused-window action failed"))
    XCTAssertTrue(error.diagnosticMessage.contains("unexpected error"))
    XCTAssertTrue(error.diagnosticMessage.contains("unexpected windowing error"))
    XCTAssertTrue(
      logs.contains(
        level: .error,
        message: "Focused-window action failed: unexpected error: unexpected windowing error"
      )
    )
  }

  func testWindowPlacementMapsMissingScreenToNotFound() async {
    let logs = LogRecorder()
    let recorder = TestFocusedWindowController(
      placeError: WindowPlacerError.screenNotFound(.orderedIndex(99))
    )
    let executor = ActionExecutor(
      configuration: .init(
        permissions: .init(ensureAccessibility: { true }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )

    let outcome = await executor.execute(
      plan: ActionPlan(steps: [
        ActionStep(method: .windowing(.placeFocusedWindow(.init(placement: .fill))))
      ]))

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .notFound)
    XCTAssertTrue(error.diagnosticMessage.contains("Window screen not found"))
    XCTAssertTrue(error.diagnosticMessage.contains("orderedIndex(99)"))
    XCTAssertTrue(
      logs.contains(level: .error, message: "Window screen not found: orderedIndex(99)")
    )
  }
}

private struct UnexpectedWindowingError: Error, CustomStringConvertible {
  var description: String {
    "unexpected windowing error"
  }
}

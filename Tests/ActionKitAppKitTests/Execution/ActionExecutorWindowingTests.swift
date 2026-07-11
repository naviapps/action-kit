import WindowKit
import WindowKitAppKit
import XCTest

import ActionKit
import ActionKitAppKit

final class ActionExecutorWindowingTests: XCTestCase {
  func testWindowAccessibilityErrorsMapByPublicErrorCases() {
    XCTAssertEqual(
      FocusedWindowControlError(
        WindowAccessibilityError.applicationUnavailable(.focused)
      ),
      .targetWindowUnavailable
    )
    XCTAssertEqual(
      FocusedWindowControlError(
        WindowAccessibilityError.windowUnavailable(.focused)
      ),
      .targetWindowUnavailable
    )
    XCTAssertEqual(
      FocusedWindowControlError(
        WindowAccessibilityError.unsupportedAccessibilityOperation(.raise)
      ),
      .unsupportedAccessibilityOperation("raise")
    )
    XCTAssertEqual(
      FocusedWindowControlError(
        WindowAccessibilityError.accessibilityOperationFailed(
          operation: .setFrame,
          failure: .cannotComplete
        )
      ),
      .accessibilityOperationFailed("setFrame: cannotComplete")
    )
  }

  func testWindowPlacerErrorsMapToStableInternalClassification() {
    XCTAssertEqual(
      FocusedWindowControlError(
        WindowPlacerError.screenNotFound(.orderedIndex(99))
      ),
      .screenNotFound("orderedIndex(99)")
    )
  }

  func testActionWindowPlacementValuesMapToWindowKitPlacements() {
    XCTAssertEqual(ActionWindowMapper.placement(.fill), WindowPlacement.fill)
    XCTAssertEqual(
      ActionWindowMapper.placement(
        .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1)
      ),
      WindowPlacement.grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))
    XCTAssertEqual(
      ActionWindowMapper.placement(
        .grid(
          columns: 2,
          rows: 3,
          column: 1,
          row: 2,
          columnSpan: 1,
          rowSpan: 1
        )
      ),
      WindowPlacement.grid(
        columns: 2,
        rows: 3,
        column: 1,
        row: 2,
        columnSpan: 1,
        rowSpan: 1
      )
    )
    XCTAssertEqual(
      ActionWindowMapper.placement(.centered(widthRatio: 0.7, heightRatio: 0.5)),
      WindowPlacement.centered(widthRatio: 0.7, heightRatio: 0.5)
    )
  }

  func testActionWindowScreenValuesMapToWindowKitValues() {
    XCTAssertEqual(ActionWindowMapper.screenTarget(.main), WindowScreenTarget.main)
    XCTAssertEqual(
      ActionWindowMapper.screenTarget(.containingWindow),
      WindowScreenTarget.containingWindow
    )
    XCTAssertEqual(
      ActionWindowMapper.screenTarget(.point(.init(x: 10, y: 20))),
      WindowScreenTarget.point(.init(x: 10, y: 20))
    )
    XCTAssertEqual(
      ActionWindowMapper.screenTarget(.displayIdentifier(7)),
      WindowScreenTarget.displayIdentifier(7)
    )
    XCTAssertEqual(
      ActionWindowMapper.screenTarget(.orderedIndex(2)),
      WindowScreenTarget.orderedIndex(2)
    )
    XCTAssertEqual(ActionWindowMapper.screenArea(.full), WindowScreenArea.full)
    XCTAssertEqual(ActionWindowMapper.screenArea(.visible), WindowScreenArea.visible)
    XCTAssertEqual(
      ActionWindowMapper.screenCycleDirection(.next),
      WindowScreenCycleDirection.next
    )
    XCTAssertEqual(
      ActionWindowMapper.screenCycleDirection(.previous),
      WindowScreenCycleDirection.previous
    )
  }

  func testWindowingExecutionReturnsPermissionDeniedWhenAccessibilityUnavailable() async {
    let logs = LogRecorder()
    let factoryInvocations = InvocationRecorder()
    let executor = ActionExecutor(
      configuration: .init(
        permissions: .init(ensureAccessibility: { false }),
        log: { level, message in logs.record(level, message) }
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
    XCTAssertTrue(logs.contains(level: .warning, message: "Permission denied: accessibility"))
  }

  func testWindowPlacementSucceedsWhenControllerAcceptsRequest() async {
    let recorder = TestFocusedWindowController()
    let executor = ActionExecutor(
      configuration: .init(permissions: .init(ensureAccessibility: { true })),
      dependencies: makeActionExecutorDependencies(makeFocusedWindowController: { recorder })
    )
    let request = WindowPlacementRequest(
      placement: .grid(columns: 3, rows: 1, column: 0, row: 0, columnSpan: 2, rowSpan: 1),
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
    let logs = LogRecorder()
    let recorder = TestFocusedWindowController(
      placeError: FocusedWindowControlError.accessibilityNotTrusted
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

    XCTAssertEqual(outcome.finalResult, .failure(.permissionDenied(.accessibility)))
    XCTAssertTrue(logs.contains(level: .warning, message: "Permission denied: accessibility"))
  }

  func testWindowMoveSkipsWhenNoFocusedWindowExists() async {
    let recorder = TestFocusedWindowController(
      moveError: FocusedWindowControlError.targetWindowUnavailable
    )
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
      placeError: FocusedWindowControlError.targetWindowUnavailable
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
    let recorder = TestFocusedWindowController(
      placeError: FocusedWindowControlError.invalidAccessibilityValue("setFrame")
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
    XCTAssertEqual(error.code, .internalError)
    XCTAssertTrue(error.diagnosticMessage.contains("Focused-window action failed"))
    XCTAssertTrue(error.diagnosticMessage.contains("invalid Accessibility window value"))
    XCTAssertTrue(error.diagnosticMessage.contains("setFrame"))
    XCTAssertTrue(
      logs.contains(
        level: .error,
        message: "Focused-window action failed: invalid Accessibility window value during setFrame"
      )
    )
  }

  func testWindowPlacementIncludesUnsupportedActionInDiagnosticMessage() async {
    let recorder = TestFocusedWindowController(
      placeError: FocusedWindowControlError.unsupportedAccessibilityOperation("raise")
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
    XCTAssertTrue(error.diagnosticMessage.contains("unsupported Accessibility window operation"))
    XCTAssertTrue(error.diagnosticMessage.contains("raise"))
  }

  func testWindowPlacementIncludesUnderlyingAccessibilityErrorInDiagnosticMessage() async {
    let recorder = TestFocusedWindowController(
      placeError: FocusedWindowControlError.accessibilityOperationFailed("cannotComplete")
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
    XCTAssertTrue(error.diagnosticMessage.contains("cannotComplete"))
  }

  func testWindowPlacementMapsUnexpectedErrorsToInternalError() async {
    let logs = LogRecorder()
    let recorder = TestFocusedWindowController(
      placeError: .unexpected("unexpected windowing error")
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
      placeError: .screenNotFound("orderedIndex(99)")
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

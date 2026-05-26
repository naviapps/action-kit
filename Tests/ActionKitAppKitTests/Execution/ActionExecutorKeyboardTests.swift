import ApplicationServices
import XCTest

@testable import ActionKit
@testable import ActionKitAppKit

final class ActionExecutorKeyboardTests: XCTestCase {
  func testKeyboardShortcutPostsParsedKeyStroke() async {
    let keyEventPoster = TestKeyEventPoster()
    let dependencies = makeActionExecutorDependencies(keyEventPoster: keyEventPoster)
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAccessibility: { true })
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [.init(method: .keyEventFromKeyboardShortcut("cmd shift z"))])

    let outcome = await executor.execute(plan: plan)
    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(keyEventPoster.postedEvents.map(\.virtualKey), [6])
    XCTAssertEqual(keyEventPoster.postedEvents.map(\.flags), [[.maskCommand, .maskShift]])
  }

  func testKeyEventPostsModifierFlags() async {
    let keyEventPoster = TestKeyEventPoster()
    let dependencies = makeActionExecutorDependencies(keyEventPoster: keyEventPoster)
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAccessibility: { true })
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(
      steps: [
        .init(
          method: .keyEvent(
            virtualKeyCode: 120,
            modifiers: [.command, .shift, .option, .control, .function]
          )
        )
      ]
    )

    let outcome = await executor.execute(plan: plan)
    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(keyEventPoster.postedEvents.map(\.virtualKey), [120])
    XCTAssertEqual(
      keyEventPoster.postedEvents.map(\.flags),
      [[.maskCommand, .maskShift, .maskAlternate, .maskControl, .maskSecondaryFn]]
    )
  }

  func testKeyStrokeReturnsAccessibilityPermissionDeniedWhenCheckerFails() async {
    let keyEventPoster = TestKeyEventPoster()
    let dependencies = makeActionExecutorDependencies(keyEventPoster: keyEventPoster)
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAccessibility: { false })
      ),
      dependencies: dependencies
    )

    let outcome = await executor.execute(.copy)
    XCTAssertEqual(outcome.finalResult, .failure(.permissionDenied(.accessibility)))
    XCTAssertEqual(outcome.attempts.count, 1)
    XCTAssertEqual(outcome.attempts.first?.result, .failure(.permissionDenied(.accessibility)))
    XCTAssertTrue(keyEventPoster.postedEvents.isEmpty)
  }

  func testKeyboardShortcutInvalidReturnsInvalidInput() async {
    let logs = LogRecorder()
    let keyEventPoster = TestKeyEventPoster()
    let accessibilityRecorder = InvocationRecorder()
    let dependencies = makeActionExecutorDependencies(keyEventPoster: keyEventPoster)
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAccessibility: {
          accessibilityRecorder.record()
          return true
        }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [.init(method: .keyEventFromKeyboardShortcut("cmd"))])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .invalidInput)
    XCTAssertEqual(error.diagnosticMessage, "Failed to parse keyboard shortcut")
    XCTAssertTrue(logs.contains(level: .warning, message: "Failed to parse keyboard shortcut"))
    XCTAssertTrue(keyEventPoster.postedEvents.isEmpty)
    XCTAssertEqual(accessibilityRecorder.invocationCount, 0)
  }

  func testKeyEventFailureReturnsInternalError() async {
    let logs = LogRecorder()
    let dependencies = makeActionExecutorDependencies(
      keyEventPoster: TestKeyEventPoster(result: false)
    )
    let executor = ActionExecutor(
      configuration: ActionExecutorConfiguration(
        permissions: .init(ensureAccessibility: { true }),
        log: { level, message in logs.record(level, message) }
      ),
      dependencies: dependencies
    )
    let plan = ActionPlan(steps: [.init(method: .keyEvent(.init(virtualKeyCode: 0)))])

    let outcome = await executor.execute(plan: plan)
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .internalError)
    XCTAssertEqual(error.diagnosticMessage, "Failed to post key stroke event")
    XCTAssertTrue(logs.contains(level: .error, message: "Failed to post key stroke event"))
  }
}

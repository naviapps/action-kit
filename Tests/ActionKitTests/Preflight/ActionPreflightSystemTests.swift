import XCTest

@testable import ActionKit

final class ActionPreflightSystemTests: XCTestCase {
  func testShowDesktopPlanIsAppleScriptThenKeyEventFallback() {
    let plan = ActionPreflight.plan(for: .showDesktop)
    XCTAssertEqual(plan.steps.count, 2)
    XCTAssertEqual(
      plan.permissionRequirements,
      .init(primary: [.accessibility, .automation], fallback: [.accessibility])
    )

    guard
      case .appleScript(source: let source, requiresSystemEvents: let requiresSystemEvents) =
        plan.steps[0].method
    else {
      return XCTFail("Expected appleScript primary")
    }
    XCTAssertTrue(requiresSystemEvents)
    XCTAssertTrue(source.contains("System Events"))
    XCTAssertTrue(source.contains("key code 103"))
    XCTAssertEqual(plan.steps[0].requiredPermissions, [.accessibility, .automation])

    assertKeyEventStep(
      plan.steps[1],
      matches: .init(action: .showDesktop, virtualKeyCode: 103, modifiers: [.function]),
      isFallback: true,
      requiredPermissions: [.accessibility]
    )
  }

  func testFallbackSystemActionsUseExpectedAppleScriptsAndFallbackKeys() {
    let cases: [(expectation: KeyEventPlanExpectation, appleScriptSnippet: String)] = [
      (
        .init(action: .lockScreen, virtualKeyCode: 12, modifiers: [.control, .command]),
        #"keystroke "q""#
      ),
      (
        .init(action: .missionControlNextSpace, virtualKeyCode: 124, modifiers: [.control]),
        "key code 124 using control down"
      ),
      (
        .init(action: .missionControlPreviousSpace, virtualKeyCode: 123, modifiers: [.control]),
        "key code 123 using control down"
      ),
      (
        .init(action: .missionControlAppExpose, virtualKeyCode: 125, modifiers: [.control]),
        "key code 125 using control down"
      ),
      (
        .init(action: .showNotificationCenter, virtualKeyCode: 100),
        "NotificationCenter"
      ),
    ]

    for (expectation, appleScriptSnippet) in cases {
      let plan = ActionPreflight.plan(for: expectation.action)
      XCTAssertEqual(plan.steps.count, 2)
      XCTAssertEqual(
        plan.permissionRequirements,
        .init(primary: [.accessibility, .automation], fallback: [.accessibility])
      )
      guard
        case .appleScript(source: let source, requiresSystemEvents: let requiresSystemEvents) =
          plan.steps[0].method
      else {
        return XCTFail("Expected appleScript primary for \(expectation.action)")
      }
      XCTAssertTrue(requiresSystemEvents)
      XCTAssertTrue(source.contains(appleScriptSnippet))
      XCTAssertEqual(plan.steps[0].requiredPermissions, [.accessibility, .automation])
      assertKeyEventStep(
        plan.steps[1],
        matches: expectation,
        isFallback: true,
        requiredPermissions: [.accessibility]
      )
    }
  }

  func testMissionControlUsesLaunchScriptThenKeyEventFallback() {
    let plan = ActionPreflight.plan(for: .missionControl)
    XCTAssertEqual(plan.steps.count, 2)
    XCTAssertEqual(
      plan.permissionRequirements,
      .init(primary: [.automation], fallback: [.accessibility])
    )

    guard
      case .appleScript(source: let source, requiresSystemEvents: let requiresSystemEvents) =
        plan.steps[0].method
    else {
      return XCTFail("Expected appleScript primary")
    }
    XCTAssertFalse(requiresSystemEvents)
    XCTAssertTrue(source.contains("Mission Control"))

    assertKeyEventStep(
      plan.steps[1],
      matches: .init(action: .missionControl, virtualKeyCode: 126, modifiers: [.control]),
      isFallback: true,
      requiredPermissions: [.accessibility]
    )
  }

  func testSingleStepAppleScriptSystemActionsUseAutomation() {
    let cases: [(action: Action, appleScriptSnippet: String)] = [
      (.toggleAppearance, "appearance preferences"),
      (.sleepMac, "sleep"),
    ]

    for (action, appleScriptSnippet) in cases {
      let plan = ActionPreflight.plan(for: action)
      XCTAssertEqual(plan.steps.count, 1)
      XCTAssertEqual(plan.permissionRequirements, .init(primary: [.automation], fallback: []))
      guard
        case .appleScript(source: let source, requiresSystemEvents: let requiresSystemEvents) =
          plan.steps.first?.method
      else {
        return XCTFail("Expected appleScript for \(action)")
      }
      XCTAssertTrue(requiresSystemEvents)
      XCTAssertTrue(source.contains("System Events"))
      XCTAssertTrue(source.contains(appleScriptSnippet))
    }
  }

  func testBrightnessActionsUseSystemKeyEvents() {
    let cases: [KeyEventPlanExpectation] = [
      .init(action: .brightnessUp, virtualKeyCode: 120, modifiers: [.function]),
      .init(action: .brightnessDown, virtualKeyCode: 122, modifiers: [.function]),
    ]

    for expectation in cases {
      assertSingleAccessibilityKeyEventPlan(expectation)
    }
  }

  func testScreenCaptureActionsUseExpectedArgumentsAndPermission() {
    let cases: [(action: Action, arguments: [String])] = [
      (.captureScreenFull, ["-x"]),
      (.captureScreenSelection, ["-i"]),
      (.captureScreenWindow, ["-i", "-W"]),
    ]

    for expectation in cases {
      let plan = ActionPreflight.plan(for: expectation.action)
      XCTAssertEqual(plan.steps.count, 1)
      XCTAssertEqual(plan.steps.first?.requiredPermissions, [.screenRecording])
      XCTAssertEqual(plan.permissionRequirements, .init(primary: [.screenRecording], fallback: []))
      guard case .screenCapture(let arguments) = plan.steps.first?.method else {
        return XCTFail("Expected screenCapture for \(expectation.action)")
      }
      XCTAssertEqual(arguments, expectation.arguments)
    }
  }

  func testSystemPlanDoesNotCreatePlaceholderStepsForUnsupportedActions() {
    XCTAssertNil(ActionPreflight.systemPlan(for: .copy))
  }
}

import XCTest

import ActionKit

final class ActionPreflightPermissionHintTests: XCTestCase {
  func testEveryActionKindProducesAtLeastOneExecutionStep() {
    for kind in ActionKind.allCases {
      let action: Action?
      if let exampleInput = kind.inputDescriptor.exampleInput {
        action = kind.makeAction(input: exampleInput)
      } else {
        action = kind.makeAction()
      }

      guard let action else {
        XCTFail("Could not create the canonical sample action for \(kind.identifier)")
        continue
      }
      XCTAssertFalse(
        ActionPreflight.plan(for: action).steps.isEmpty,
        "Missing execution plan for \(kind.identifier)"
      )
    }
  }

  func testPermissionsForActionKindsDoNotRequireConstructedActions() {
    let cases: [(kind: ActionKind, permissions: ActionPermissionSet)] = [
      (.windowPlacement, .init(primary: [.accessibility], fallback: [])),
      (.keyboardShortcut, .init(primary: [.accessibility], fallback: [])),
      (.openURL, .init(primary: [], fallback: [])),
      (.launchApplication, .init(primary: [], fallback: [])),
      (.runShortcut, .init(primary: [], fallback: [])),
      (.openFolder, .init(primary: [], fallback: [])),
      (.showDesktop, .init(primary: [.accessibility, .automation], fallback: [.accessibility])),
      (.windowMove, .init(primary: [.accessibility], fallback: [])),
    ]

    for expectation in cases {
      XCTAssertEqual(
        ActionPreflight.permissions(forKind: expectation.kind),
        expectation.permissions,
        "Unexpected permissions for \(expectation.kind)"
      )
    }
  }

  func testPermissionHintsUseActionSpecificReasons() {
    XCTAssertEqual(
      ActionPreflight.permissionHints(for: .copy),
      [.init(permission: .accessibility, reason: .accessibilityKeyEvent)]
    )
    XCTAssertEqual(
      ActionPreflight.permissionHints(forKind: ActionKind.windowPlacement),
      [.init(permission: .accessibility, reason: .accessibilityWindowing)]
    )
    XCTAssertEqual(
      ActionPreflight.permissionHints(forKind: ActionKind.toggleAppearance),
      [.init(permission: .automation, reason: .automationAppleEvents)]
    )
    XCTAssertEqual(
      ActionPreflight.permissionHints(forKind: ActionKind.captureScreenFull),
      [.init(permission: .screenRecording, reason: .screenRecordingCapture)]
    )
    XCTAssertTrue(ActionPreflight.permissionHints(for: .launchApplication("")).isEmpty)
  }

  func testPermissionHintsForActionKindsDoNotRequireConstructedActions() {
    let cases: [(kind: ActionKind, hints: [ActionPermissionHint])] = [
      (.windowMove, [.init(permission: .accessibility, reason: .accessibilityWindowing)]),
      (.keyboardShortcut, [.init(permission: .accessibility, reason: .accessibilityKeyEvent)]),
      (.runShortcut, []),
    ]

    for expectation in cases {
      XCTAssertEqual(
        ActionPreflight.permissionHints(forKind: expectation.kind),
        expectation.hints,
        "Unexpected permission hints for \(expectation.kind)"
      )
    }
  }

  func testPermissionHintsUseExecutionPlanOrder() {
    XCTAssertEqual(
      ActionPreflight.permissionHints(forKind: ActionKind.showDesktop),
      [
        .init(permission: .accessibility, reason: .accessibility),
        .init(permission: .automation, reason: .automationAppleEvents),
      ]
    )
  }
}

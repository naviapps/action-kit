import XCTest

import ActionKit

final class ActionMethodTests: XCTestCase {
  func testRequiredPermissionsAreDerivedFromExecutionSemantics() {
    let expectations: [(method: ActionMethod, permissions: Set<ActionPermission>)] = [
      (.keyEvent(virtualKeyCode: 1), [.accessibility]),
      (.keyEventFromKeyboardShortcut("cmd+a"), [.accessibility]),
      (
        .appleScript(
          source: "tell app",
          launchesSystemEvents: false,
          usesAccessibility: false
        ),
        [.automation]
      ),
      (
        .appleScript(
          source: "tell app",
          launchesSystemEvents: true,
          usesAccessibility: true
        ),
        [.accessibility, .automation]
      ),
      (.openURL("https://example.com"), []),
      (.openFolder("/Applications"), []),
      (.launchApplication("Safari"), []),
      (.runShortcut("Morning Routine"), []),
      (.hideFrontmostApplication, []),
      (.terminateFrontmostApplication, []),
      (.screenCapture(arguments: ["-x"]), [.screenRecording]),
      (
        .windowing(.moveFocusedWindow(.init(direction: .next))),
        [.accessibility]
      ),
    ]

    for expectation in expectations {
      XCTAssertEqual(
        expectation.method.requiredPermissions,
        expectation.permissions,
        "Unexpected permissions for \(expectation.method)"
      )
    }
  }

  func testActionModifierRawValuesAreCanonical() {
    XCTAssertEqual(ActionModifiers.command.rawValue, 1 << 0)
    XCTAssertEqual(ActionModifiers.shift.rawValue, 1 << 1)
    XCTAssertEqual(ActionModifiers.option.rawValue, 1 << 2)
    XCTAssertEqual(ActionModifiers.control.rawValue, 1 << 3)
    XCTAssertEqual(ActionModifiers.function.rawValue, 1 << 4)
  }

  func testKeyEventConvenienceFactoryUsesEmptyModifiersByDefault() {
    let method = ActionMethod.keyEvent(virtualKeyCode: 12)

    switch method {
    case .keyEvent(let event):
      XCTAssertEqual(event.virtualKeyCode, 12)
      XCTAssertEqual(event.modifiers, [])
    default:
      XCTFail("Expected keyEvent")
    }
  }

  func testKeyEventConvenienceFactory() {
    let method = ActionMethod.keyEvent(virtualKeyCode: 12, modifiers: [.command])

    switch method {
    case .keyEvent(let event):
      XCTAssertEqual(event.virtualKeyCode, 12)
      XCTAssertEqual(event.modifiers, [.command])
    default:
      XCTFail("Expected keyEvent")
    }
  }
}

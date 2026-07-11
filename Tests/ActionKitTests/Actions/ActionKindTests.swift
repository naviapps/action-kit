import XCTest

import ActionKit

final class ActionKindTests: XCTestCase {
  func testActionKindIdentifiersAreCanonical() {
    XCTAssertEqual(
      ActionKind.allCases.map(\.identifier),
      [
        "action.editing.copy",
        "action.editing.paste",
        "action.editing.cut",
        "action.editing.undo",
        "action.editing.redo",
        "action.frontmost-application.hide",
        "action.frontmost-application.quit",
        "action.media.volume-up",
        "action.media.volume-down",
        "action.media.volume-mute",
        "action.media.play-pause",
        "action.media.next",
        "action.media.previous",
        "action.keyboard.shortcut",
        "action.workspace.open-url",
        "action.workspace.launch-application",
        "action.workspace.run-shortcut",
        "action.workspace.open-folder",
        "action.system.mission-control",
        "action.system.show-desktop",
        "action.system.lock-screen",
        "action.system.sleep-mac",
        "action.system.mission-control-next-space",
        "action.system.mission-control-previous-space",
        "action.system.mission-control-app-expose",
        "action.system.brightness-up",
        "action.system.brightness-down",
        "action.system.toggle-appearance",
        "action.system.show-notification-center",
        "action.system.capture-screen-full",
        "action.system.capture-screen-selection",
        "action.system.capture-screen-window",
        "action.window.placement",
        "action.window.move",
      ]
    )
  }

  func testActionKindIdentifiersAreUnique() {
    XCTAssertEqual(Set(ActionKind.allCases.map(\.identifier)).count, ActionKind.allCases.count)
  }

  func testActionKindCanBeCreatedFromIdentifier() {
    for kind in ActionKind.allCases {
      XCTAssertEqual(ActionKind(identifier: kind.identifier), kind)
    }

    XCTAssertNil(ActionKind(identifier: "openURL"))
    XCTAssertNil(ActionKind(identifier: "action.workspace.missing"))
  }

  func testActionKindRoundTripsCodableIdentifier() throws {
    for kind in ActionKind.allCases {
      let data = try JSONEncoder().encode(kind)

      XCTAssertEqual(try JSONDecoder().decode(ActionKind.self, from: data), kind)
    }
  }

  func testActionKindCodableUsesIdentifier() throws {
    let data = try JSONEncoder().encode(ActionKind.openURL)

    XCTAssertEqual(String(decoding: data, as: UTF8.self), #""action.workspace.open-url""#)
  }

  func testActionKindCodableRejectsUnsupportedIdentifier() {
    let data = Data(#""openURL""#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(ActionKind.self, from: data)) { error in
      guard case DecodingError.dataCorrupted(let context) = error else {
        XCTFail("Expected dataCorrupted, got \(error)")
        return
      }

      XCTAssertTrue(
        context.debugDescription.contains("Unsupported action kind identifier: openURL")
      )
    }
  }
}

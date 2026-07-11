import XCTest

import ActionKit

final class ActionInputShapeTests: XCTestCase {
  func testActionInputShapeRoundTripsCodable() throws {
    for inputShape in ActionInputShape.allCases {
      let data = try JSONEncoder().encode(inputShape)
      XCTAssertEqual(try JSONDecoder().decode(ActionInputShape.self, from: data), inputShape)
    }
  }

  func testActionInputShapeRawValuesAreCanonical() {
    XCTAssertEqual(
      ActionInputShape.allCases.map(\.rawValue),
      [
        "none",
        "string",
        "window-placement",
        "window-move",
      ]
    )
  }

  func testInputShapeForActionKinds() {
    let inputShapes = Dictionary(
      uniqueKeysWithValues: ActionKind.allCases.map { ($0, $0.inputDescriptor.shape) }
    )

    XCTAssertEqual(
      inputShapes,
      [
        .copy: .none,
        .paste: .none,
        .cut: .none,
        .undo: .none,
        .redo: .none,
        .hideFrontmostApplication: .none,
        .quitFrontmostApplication: .none,
        .volumeUp: .none,
        .volumeDown: .none,
        .volumeMute: .none,
        .mediaPlayPause: .none,
        .mediaNext: .none,
        .mediaPrevious: .none,
        .keyboardShortcut: .string,
        .openURL: .string,
        .launchApplication: .string,
        .runShortcut: .string,
        .openFolder: .string,
        .missionControl: .none,
        .showDesktop: .none,
        .lockScreen: .none,
        .sleepMac: .none,
        .missionControlNextSpace: .none,
        .missionControlPreviousSpace: .none,
        .missionControlAppExpose: .none,
        .brightnessUp: .none,
        .brightnessDown: .none,
        .toggleAppearance: .none,
        .showNotificationCenter: .none,
        .captureScreenFull: .none,
        .captureScreenSelection: .none,
        .captureScreenWindow: .none,
        .windowPlacement: .windowPlacement,
        .windowMove: .windowMove,
      ]
    )
  }
}

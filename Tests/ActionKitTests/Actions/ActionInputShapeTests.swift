import XCTest

@testable import ActionKit

final class ActionInputShapeTests: XCTestCase {
  func testActionInputShapeCasesAreStable() {
    XCTAssertEqual(
      ActionInputShape.allCases,
      [
        .none,
        .string,
        .windowPlacement,
        .windowMove,
      ]
    )
  }

  func testActionInputShapeRoundTripsCodable() throws {
    for inputShape in ActionInputShape.allCases {
      let data = try JSONEncoder().encode(inputShape)
      XCTAssertEqual(try JSONDecoder().decode(ActionInputShape.self, from: data), inputShape)
    }
  }

  func testActionInputShapeRawValuesAreStable() {
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
      uniqueKeysWithValues: ActionKind.allCases.map { ($0, $0.inputShape) }
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
        .windowMaximize: .none,
        .windowLeftHalf: .none,
        .windowRightHalf: .none,
        .windowTopHalf: .none,
        .windowBottomHalf: .none,
        .windowCenter: .none,
        .windowMoveToNextScreen: .none,
        .windowMoveToPreviousScreen: .none,
        .windowPlacement: .windowPlacement,
        .windowMove: .windowMove,
      ]
    )
  }
}

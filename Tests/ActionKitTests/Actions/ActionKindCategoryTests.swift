import XCTest

import ActionKit

final class ActionKindCategoryTests: XCTestCase {
  func testActionKindCategoriesUseEveryPublicCategory() {
    XCTAssertEqual(Set(ActionKind.allCases.map(\.category)), Set(ActionCategory.allCases))
  }

  func testActionKindCategoriesCoverAllCases() {
    let categories = Dictionary(uniqueKeysWithValues: ActionKind.allCases.map { ($0, $0.category) })

    XCTAssertEqual(
      categories,
      [
        .copy: .editing,
        .paste: .editing,
        .cut: .editing,
        .undo: .editing,
        .redo: .editing,
        .hideFrontmostApplication: .frontmostApplication,
        .quitFrontmostApplication: .frontmostApplication,
        .volumeUp: .media,
        .volumeDown: .media,
        .volumeMute: .media,
        .mediaPlayPause: .media,
        .mediaNext: .media,
        .mediaPrevious: .media,
        .keyboardShortcut: .keyboard,
        .openURL: .workspace,
        .launchApplication: .workspace,
        .runShortcut: .workspace,
        .openFolder: .workspace,
        .missionControl: .system,
        .showDesktop: .system,
        .lockScreen: .system,
        .sleepMac: .system,
        .missionControlNextSpace: .system,
        .missionControlPreviousSpace: .system,
        .missionControlAppExpose: .system,
        .brightnessUp: .system,
        .brightnessDown: .system,
        .toggleAppearance: .system,
        .showNotificationCenter: .system,
        .captureScreenFull: .system,
        .captureScreenSelection: .system,
        .captureScreenWindow: .system,
        .windowPlacement: .window,
        .windowMove: .window,
      ]
    )
  }
}

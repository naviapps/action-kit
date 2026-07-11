import ActionKit

enum ActionTestFixtures {
  static var actionKindCases: [(action: Action, kind: ActionKind)] {
    let cases =
      inputFreeActionKindCases
      + inputActionCases.map { (action: $0.action, kind: $0.kind) }
    let actionsByKind = Dictionary(uniqueKeysWithValues: cases.map { ($0.kind, $0.action) })

    return ActionKind.allCases.compactMap { kind in
      actionsByKind[kind].map { action in (action: action, kind: kind) }
    }
  }

  static var inputActionCases: [(kind: ActionKind, input: ActionInput, action: Action)] {
    let placement = WindowPlacementRequest(
      placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))
    let move = WindowMoveRequest(direction: .next)

    return [
      (.keyboardShortcut, .string("cmd+c"), .keyboardShortcut("cmd+c")),
      (.openURL, .string("https://example.com"), .openURL("https://example.com")),
      (.launchApplication, .string("com.example.App"), .launchApplication("com.example.App")),
      (.runShortcut, .string("Daily"), .runShortcut("Daily")),
      (.openFolder, .string("/Applications"), .openFolder("/Applications")),
      (.windowPlacement, .windowPlacement(placement), .windowPlacement(placement)),
      (.windowMove, .windowMove(move), .windowMove(move)),
    ]
  }

  private static var inputFreeActionKindCases: [(action: Action, kind: ActionKind)] {
    [
      (.copy, .copy),
      (.paste, .paste),
      (.cut, .cut),
      (.undo, .undo),
      (.redo, .redo),
      (.hideFrontmostApplication, .hideFrontmostApplication),
      (.quitFrontmostApplication, .quitFrontmostApplication),
      (.volumeUp, .volumeUp),
      (.volumeDown, .volumeDown),
      (.volumeMute, .volumeMute),
      (.mediaPlayPause, .mediaPlayPause),
      (.mediaNext, .mediaNext),
      (.mediaPrevious, .mediaPrevious),
      (.missionControl, .missionControl),
      (.showDesktop, .showDesktop),
      (.lockScreen, .lockScreen),
      (.sleepMac, .sleepMac),
      (.missionControlNextSpace, .missionControlNextSpace),
      (.missionControlPreviousSpace, .missionControlPreviousSpace),
      (.missionControlAppExpose, .missionControlAppExpose),
      (.brightnessUp, .brightnessUp),
      (.brightnessDown, .brightnessDown),
      (.toggleAppearance, .toggleAppearance),
      (.showNotificationCenter, .showNotificationCenter),
      (.captureScreenFull, .captureScreenFull),
      (.captureScreenSelection, .captureScreenSelection),
      (.captureScreenWindow, .captureScreenWindow),
    ]
  }
}

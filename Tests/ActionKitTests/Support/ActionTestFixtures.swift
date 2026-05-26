import WindowKit

@testable import ActionKit

enum ActionTestFixtures {
  typealias ActionKindCase = (action: Action, kind: ActionKind)
  typealias InputActionCase = (kind: ActionKind, input: ActionInput, action: Action)

  static var actionKindCases: [ActionKindCase] {
    let cases =
      inputFreeActionKindCases
      + inputActionCases.map { (action: $0.action, kind: $0.kind) }
    let actionsByKind = Dictionary(uniqueKeysWithValues: cases.map { ($0.kind, $0.action) })

    return ActionKind.allCases.map { kind in
      guard let action = actionsByKind[kind] else {
        fatalError("Missing representative action fixture for \(kind).")
      }
      return (action: action, kind: kind)
    }
  }

  static var inputActionCases: [InputActionCase] {
    let placement = WindowPlacementRequest(placement: .leftHalf)
    let move = WindowMoveRequest(direction: .next)

    return [
      (.keyboardShortcut, .string("cmd+c"), .keyboardShortcut("cmd+c")),
      (.openURL, .string("https://example.com"), .openURL("https://example.com")),
      (.launchApplication, .string("com.example.App"), .launchApplication("com.example.App")),
      (.runShortcut, .string("Daily"), .runShortcut("Daily")),
      (.openFolder, .string("/tmp"), .openFolder("/tmp")),
      (.windowPlacement, .windowPlacement(placement), .windowPlacement(placement)),
      (.windowMove, .windowMove(move), .windowMove(move)),
    ]
  }

  private static var inputFreeActionKindCases: [ActionKindCase] {
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
      (.windowMaximize, .windowMaximize),
      (.windowLeftHalf, .windowLeftHalf),
      (.windowRightHalf, .windowRightHalf),
      (.windowTopHalf, .windowTopHalf),
      (.windowBottomHalf, .windowBottomHalf),
      (.windowCenter, .windowCenter),
      (.windowMoveToNextScreen, .windowMoveToNextScreen),
      (.windowMoveToPreviousScreen, .windowMoveToPreviousScreen),
    ]
  }
}

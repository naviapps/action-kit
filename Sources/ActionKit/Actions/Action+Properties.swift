extension Action {
  /// The action kind represented by this action.
  public var kind: ActionKind {
    switch self {
    case .copy: .copy
    case .paste: .paste
    case .cut: .cut
    case .undo: .undo
    case .redo: .redo
    case .hideFrontmostApplication: .hideFrontmostApplication
    case .quitFrontmostApplication: .quitFrontmostApplication
    case .volumeUp: .volumeUp
    case .volumeDown: .volumeDown
    case .volumeMute: .volumeMute
    case .mediaPlayPause: .mediaPlayPause
    case .mediaNext: .mediaNext
    case .mediaPrevious: .mediaPrevious
    case .keyboardShortcut: .keyboardShortcut
    case .openURL: .openURL
    case .launchApplication: .launchApplication
    case .runShortcut: .runShortcut
    case .openFolder: .openFolder
    case .missionControl: .missionControl
    case .showDesktop: .showDesktop
    case .lockScreen: .lockScreen
    case .sleepMac: .sleepMac
    case .missionControlNextSpace: .missionControlNextSpace
    case .missionControlPreviousSpace: .missionControlPreviousSpace
    case .missionControlAppExpose: .missionControlAppExpose
    case .brightnessUp: .brightnessUp
    case .brightnessDown: .brightnessDown
    case .toggleAppearance: .toggleAppearance
    case .showNotificationCenter: .showNotificationCenter
    case .captureScreenFull: .captureScreenFull
    case .captureScreenSelection: .captureScreenSelection
    case .captureScreenWindow: .captureScreenWindow
    case .windowPlacement: .windowPlacement
    case .windowMove: .windowMove
    }
  }

  /// The normalized input carried by this action.
  ///
  /// Input-free actions and string-backed actions with empty normalized input return `nil`.
  public var input: ActionInput? {
    switch self {
    case .keyboardShortcut(let value),
      .openURL(let value),
      .launchApplication(let value),
      .runShortcut(let value),
      .openFolder(let value):
      return ActionInput.normalizedString(value).map(ActionInput.string)
    case .windowPlacement(let request):
      return .windowPlacement(request)
    case .windowMove(let request):
      return .windowMove(request)
    case .copy, .paste, .cut, .undo, .redo, .hideFrontmostApplication, .quitFrontmostApplication,
      .volumeUp, .volumeDown, .volumeMute, .mediaPlayPause, .mediaNext, .mediaPrevious,
      .missionControl, .showDesktop, .lockScreen, .sleepMac, .missionControlNextSpace,
      .missionControlPreviousSpace, .missionControlAppExpose, .brightnessUp, .brightnessDown,
      .toggleAppearance, .showNotificationCenter, .captureScreenFull, .captureScreenSelection,
      .captureScreenWindow:
      return nil
    }
  }
}

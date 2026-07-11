extension ActionKind {
  /// Creates an executable action from this kind when no host-supplied input is required.
  ///
  /// - Returns: An executable action, or `nil` when this kind requires host-supplied input.
  public func makeAction() -> Action? {
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
    case .keyboardShortcut: nil
    case .openURL: nil
    case .launchApplication: nil
    case .runShortcut: nil
    case .openFolder: nil
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
    case .windowPlacement: nil
    case .windowMove: nil
    }
  }

  /// Creates an executable action from this kind and host-supplied input.
  ///
  /// - Parameter input: The host-supplied value required by this action kind.
  /// - Returns: An executable action, or `nil` when this kind does not accept input or the input
  ///   shape does not match.
  public func makeAction(input: ActionInput) -> Action? {
    switch self {
    case .keyboardShortcut:
      guard let normalized = Self.normalizedString(from: input) else { return nil }
      return .keyboardShortcut(normalized)
    case .openURL:
      guard let normalized = Self.normalizedString(from: input) else { return nil }
      return .openURL(normalized)
    case .launchApplication:
      guard let normalized = Self.normalizedString(from: input) else { return nil }
      return .launchApplication(normalized)
    case .runShortcut:
      guard let normalized = Self.normalizedString(from: input) else { return nil }
      return .runShortcut(normalized)
    case .openFolder:
      guard let normalized = Self.normalizedString(from: input) else { return nil }
      return .openFolder(normalized)
    case .windowPlacement:
      guard case .windowPlacement(let request) = input else { return nil }
      return .windowPlacement(request)
    case .windowMove:
      guard case .windowMove(let request) = input else { return nil }
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

  private static func normalizedString(from input: ActionInput) -> String? {
    guard case .string(let value) = input else {
      return nil
    }
    return ActionInput.normalizedString(value)
  }
}

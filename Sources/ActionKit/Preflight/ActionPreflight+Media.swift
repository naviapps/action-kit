extension ActionPreflight {
  static func mediaPlan(for action: Action) -> ActionPlan? {
    guard let method = mediaKeyEvent(for: action) else {
      return nil
    }

    return singleStepPlan(method: method)
  }

  private static func mediaKeyEvent(for action: Action) -> ActionMethod? {
    switch action {
    case .volumeUp:
      .keyEvent(virtualKeyCode: VirtualKeyCode.volumeUp)
    case .volumeDown:
      .keyEvent(virtualKeyCode: VirtualKeyCode.volumeDown)
    case .volumeMute:
      .keyEvent(virtualKeyCode: VirtualKeyCode.volumeMute)
    case .mediaPlayPause:
      .keyEvent(virtualKeyCode: VirtualKeyCode.mediaPlayPause)
    case .mediaNext:
      .keyEvent(virtualKeyCode: VirtualKeyCode.mediaNext)
    case .mediaPrevious:
      .keyEvent(virtualKeyCode: VirtualKeyCode.mediaPrevious)
    default:
      nil
    }
  }
}

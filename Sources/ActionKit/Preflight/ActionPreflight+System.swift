extension ActionPreflight {
  private enum SystemAppleScript {
    static let missionControl = "tell application \"Mission Control\" to launch"
    static let sleep = "tell application \"System Events\" to sleep"

    static let toggleAppearance = """
      tell application "System Events"
          tell appearance preferences
              set dark mode to not dark mode
          end tell
      end tell
      """

    static let lockScreen = """
      tell application "System Events" to keystroke "q" using {control down, command down}
      """

    static func systemEventsKeyCode(_ virtualKeyCode: UInt16) -> String {
      "tell application \"System Events\" to key code \(virtualKeyCode)"
    }

    static func systemEventsKeyCodeWithControl(_ virtualKeyCode: UInt16) -> String {
      "tell application \"System Events\" to key code \(virtualKeyCode) using control down"
    }

    static let showNotificationCenter = """
      tell application "System Events"
          try
              click menu bar item 1 of menu bar 1 of application process "NotificationCenter"
          on error
              try
                  click menu bar item 1 of menu bar 1 of application process "ControlCenter"
              on error
                  key code \(VirtualKeyCode.notificationCenterAppleScriptFallback)
              end try
          end try
      end tell
      """
  }

  static func systemPlan(for action: Action) -> ActionPlan? {
    switch action {
    case .captureScreenFull, .captureScreenSelection, .captureScreenWindow:
      return screenCapturePlan(for: action)
    case .toggleAppearance:
      return singleStepPlan(
        method: .appleScript(
          source: SystemAppleScript.toggleAppearance, requiresSystemEvents: true),
        requiredPermissions: [.automation]
      )
    case .missionControl:
      return .init(steps: [
        .init(
          method: .appleScript(
            source: SystemAppleScript.missionControl, requiresSystemEvents: false),
          requiredPermissions: [.automation]
        ),
        .init(
          method: .keyEvent(
            virtualKeyCode: VirtualKeyCode.missionControlFallback,
            modifiers: [.control]
          ),
          requiredPermissions: [.accessibility],
          isFallback: true
        ),
      ])
    case .brightnessUp:
      return singleStepPlan(
        method: .keyEvent(virtualKeyCode: VirtualKeyCode.brightnessUp, modifiers: [.function]),
        requiredPermissions: [.accessibility]
      )
    case .brightnessDown:
      return singleStepPlan(
        method: .keyEvent(virtualKeyCode: VirtualKeyCode.brightnessDown, modifiers: [.function]),
        requiredPermissions: [.accessibility]
      )
    case .showDesktop, .lockScreen, .missionControlNextSpace, .missionControlPreviousSpace,
      .missionControlAppExpose,
      .showNotificationCenter:
      return systemFallbackPlan(for: action)
    case .sleepMac:
      return singleStepPlan(
        method: .appleScript(source: SystemAppleScript.sleep, requiresSystemEvents: true),
        requiredPermissions: [.automation]
      )
    default:
      return nil
    }
  }

  private static func screenCapturePlan(for action: Action) -> ActionPlan? {
    let arguments: [String]
    switch action {
    case .captureScreenFull:
      arguments = ["-x"]
    case .captureScreenSelection:
      arguments = ["-i"]
    case .captureScreenWindow:
      arguments = ["-i", "-W"]
    default:
      return nil
    }
    return singleStepPlan(
      method: .screenCapture(arguments: arguments),
      requiredPermissions: [.screenRecording]
    )
  }

  private static func systemFallbackPlan(for action: Action) -> ActionPlan? {
    let appleScript: String
    let fallback: ActionMethod

    switch action {
    case .showDesktop:
      appleScript = SystemAppleScript.systemEventsKeyCode(VirtualKeyCode.showDesktopFallback)
      fallback = .keyEvent(
        virtualKeyCode: VirtualKeyCode.showDesktopFallback,
        modifiers: [.function]
      )
    case .lockScreen:
      appleScript = SystemAppleScript.lockScreen
      fallback = .keyEvent(
        virtualKeyCode: VirtualKeyCode.lockScreenFallback, modifiers: [.control, .command])
    case .missionControlNextSpace:
      appleScript = SystemAppleScript.systemEventsKeyCodeWithControl(VirtualKeyCode.spaceRight)
      fallback = .keyEvent(virtualKeyCode: VirtualKeyCode.spaceRight, modifiers: [.control])
    case .missionControlPreviousSpace:
      appleScript = SystemAppleScript.systemEventsKeyCodeWithControl(VirtualKeyCode.spaceLeft)
      fallback = .keyEvent(virtualKeyCode: VirtualKeyCode.spaceLeft, modifiers: [.control])
    case .missionControlAppExpose:
      appleScript = SystemAppleScript.systemEventsKeyCodeWithControl(VirtualKeyCode.downArrow)
      fallback = .keyEvent(virtualKeyCode: VirtualKeyCode.downArrow, modifiers: [.control])
    case .showNotificationCenter:
      appleScript = SystemAppleScript.showNotificationCenter
      fallback = .keyEvent(virtualKeyCode: VirtualKeyCode.notificationCenterFallback)
    default:
      return nil
    }

    return systemEventsAppleScriptFallbackPlan(source: appleScript, fallback: fallback)
  }

  private static func systemEventsAppleScriptFallbackPlan(
    source: String,
    fallback: ActionMethod
  ) -> ActionPlan {
    .init(steps: [
      .init(
        method: .appleScript(source: source, requiresSystemEvents: true),
        requiredPermissions: [.accessibility, .automation]
      ),
      .init(
        method: fallback,
        requiredPermissions: [.accessibility],
        isFallback: true
      ),
    ])
  }
}

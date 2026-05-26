extension ActionPreflight {
  enum VirtualKeyCode {
    static let copy: UInt16 = 8
    static let paste: UInt16 = 9
    static let cut: UInt16 = 7
    static let undo: UInt16 = 6
    static let mediaPlayPause: UInt16 = 0x10
    static let mediaNext: UInt16 = 0x11
    static let mediaPrevious: UInt16 = 0x12
    static let volumeUp: UInt16 = 0x48
    static let volumeDown: UInt16 = 0x49
    static let volumeMute: UInt16 = 0x4A
    static let lockScreenFallback: UInt16 = 12
    static let missionControlFallback: UInt16 = 126
    static let showDesktopFallback: UInt16 = 103
    static let spaceRight: UInt16 = 124
    static let spaceLeft: UInt16 = 123
    static let downArrow: UInt16 = 125
    static let notificationCenterFallback: UInt16 = 100
    static let notificationCenterAppleScriptFallback: UInt16 = 160
    static let brightnessUp: UInt16 = 120
    static let brightnessDown: UInt16 = 122
  }
}

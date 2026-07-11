import ApplicationServices

package protocol KeyEventPosting: Sendable {
  func postKeyStroke(virtualKey: CGKeyCode, flags: CGEventFlags) -> Bool
}

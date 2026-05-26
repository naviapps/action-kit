import CoreGraphics

struct LiveScreenCaptureAccessChecker: ScreenCaptureAccessChecking {
  private let checkAccess: @Sendable () -> Bool

  init(checkAccess: @escaping @Sendable () -> Bool = { CGPreflightScreenCaptureAccess() }) {
    self.checkAccess = checkAccess
  }

  func hasAccess() -> Bool {
    checkAccess()
  }
}

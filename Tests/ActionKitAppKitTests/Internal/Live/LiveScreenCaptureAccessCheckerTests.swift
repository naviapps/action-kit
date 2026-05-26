import XCTest

@testable import ActionKitAppKit

final class LiveScreenCaptureAccessCheckerTests: XCTestCase {
  func testHasAccessReturnsInjectedGrantedState() {
    let checker = LiveScreenCaptureAccessChecker {
      true
    }

    XCTAssertTrue(checker.hasAccess())
  }

  func testHasAccessReturnsInjectedDeniedState() {
    let checker = LiveScreenCaptureAccessChecker {
      false
    }

    XCTAssertFalse(checker.hasAccess())
  }
}

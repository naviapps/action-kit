import XCTest

@testable import ActionKit

final class ActionPreflightMediaTests: XCTestCase {
  func testMediaActionsUseExpectedKeyEvents() {
    let cases: [KeyEventPlanExpectation] = [
      .init(action: .volumeUp, virtualKeyCode: 0x48),
      .init(action: .volumeDown, virtualKeyCode: 0x49),
      .init(action: .volumeMute, virtualKeyCode: 0x4A),
      .init(action: .mediaPlayPause, virtualKeyCode: 0x10),
      .init(action: .mediaNext, virtualKeyCode: 0x11),
      .init(action: .mediaPrevious, virtualKeyCode: 0x12),
    ]

    for expectation in cases {
      assertSingleAccessibilityKeyEventPlan(expectation)
    }
  }

  func testMediaPlanDoesNotHandleOtherActions() {
    XCTAssertNil(ActionPreflight.mediaPlan(for: .copy))
    XCTAssertNil(ActionPreflight.mediaPlan(for: .brightnessUp))
    XCTAssertNil(ActionPreflight.mediaPlan(for: .showDesktop))
  }
}

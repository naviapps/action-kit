import XCTest

@testable import ActionKit

final class ActionMethodTests: XCTestCase {
  func testActionModifierRawValuesAreStable() {
    XCTAssertEqual(ActionModifiers.command.rawValue, 1 << 0)
    XCTAssertEqual(ActionModifiers.shift.rawValue, 1 << 1)
    XCTAssertEqual(ActionModifiers.option.rawValue, 1 << 2)
    XCTAssertEqual(ActionModifiers.control.rawValue, 1 << 3)
    XCTAssertEqual(ActionModifiers.function.rawValue, 1 << 4)
  }

  func testKeyEventConvenienceFactoryUsesEmptyModifiersByDefault() {
    let method = ActionMethod.keyEvent(virtualKeyCode: 12)

    switch method {
    case .keyEvent(let event):
      XCTAssertEqual(event.virtualKeyCode, 12)
      XCTAssertEqual(event.modifiers, [])
    default:
      XCTFail("Expected keyEvent")
    }
  }

  func testKeyEventConvenienceFactory() {
    let method = ActionMethod.keyEvent(virtualKeyCode: 12, modifiers: [.command])

    switch method {
    case .keyEvent(let event):
      XCTAssertEqual(event.virtualKeyCode, 12)
      XCTAssertEqual(event.modifiers, [.command])
    default:
      XCTFail("Expected keyEvent")
    }
  }
}

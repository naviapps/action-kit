import WindowKit
import XCTest

@testable import ActionKit

final class ActionPropertiesTests: XCTestCase {
  func testActionKindMatchesEveryActionCase() {
    let cases = ActionTestFixtures.actionKindCases

    XCTAssertEqual(cases.count, ActionKind.allCases.count)
    XCTAssertEqual(Set(cases.map(\.kind)), Set(ActionKind.allCases))
    for (action, kind) in cases {
      XCTAssertEqual(action.kind, kind)
    }
  }

  func testActionInputIsNilForInputFreeActions() {
    for (action, kind) in ActionTestFixtures.actionKindCases where kind.inputShape == .none {
      XCTAssertNil(action.input, "\(action) should not expose input")
    }
  }

  func testActionInputNormalizesStringValues() {
    XCTAssertEqual(
      Set(Self.stringInputFixtures.map { $0.action.kind }),
      Set(ActionKind.allCases.filter { $0.inputShape == .string })
    )

    for (action, expectedInput) in Self.stringInputFixtures {
      XCTAssertEqual(action.input, expectedInput)
    }
  }

  func testActionInputRejectsBlankStringValues() {
    XCTAssertEqual(
      Set(Self.blankStringInputActions.map(\.kind)),
      Set(ActionKind.allCases.filter { $0.inputShape == .string })
    )

    for action in Self.blankStringInputActions {
      XCTAssertNil(action.input)
    }
  }

  func testActionInputPreservesWindowRequests() {
    let placement = WindowPlacementRequest(placement: .leftHalf)
    let move = WindowMoveRequest(direction: .next, preservesRelativePosition: false)

    XCTAssertEqual(Action.windowPlacement(placement).input, .windowPlacement(placement))
    XCTAssertEqual(Action.windowMove(move).input, .windowMove(move))
  }

  private static var stringInputFixtures: [(action: Action, input: ActionInput)] {
    [
      (Action.keyboardShortcut("  cmd+c  "), .string("cmd+c")),
      (Action.openURL("  https://example.com  "), .string("https://example.com")),
      (Action.launchApplication("  Safari  "), .string("Safari")),
      (Action.runShortcut("  Daily  "), .string("Daily")),
      (Action.openFolder("  ~/Downloads  "), .string("~/Downloads")),
    ]
  }

  private static var blankStringInputActions: [Action] {
    let blank = " \n\t "

    return [
      .keyboardShortcut(blank),
      .openURL(blank),
      .launchApplication(blank),
      .runShortcut(blank),
      .openFolder(blank),
    ]
  }
}

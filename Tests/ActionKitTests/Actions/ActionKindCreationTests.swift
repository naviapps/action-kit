import WindowKit
import XCTest

@testable import ActionKit

final class ActionKindCreationTests: XCTestCase {
  func testActionsCoverActionKindsWithoutInput() {
    for kind in ActionKind.allCases {
      if kind.inputShape == .none {
        XCTAssertEqual(kind.action()?.kind, kind)
      } else {
        XCTAssertNil(kind.action())
      }
    }
  }

  func testActionKindCreatesActionsForAllInputRequiringKinds() {
    let fixtures = ActionTestFixtures.inputActionCases
    let inputRequiringKinds = ActionKind.allCases.filter { $0.inputShape != .none }

    XCTAssertEqual(fixtures.count, inputRequiringKinds.count)
    XCTAssertEqual(Set(fixtures.map(\.kind)), Set(inputRequiringKinds))
    for (kind, input, action) in fixtures {
      XCTAssertEqual(kind.action(input: input), action)
    }
  }

  func testInputFreeActionKindsRejectHostInput() {
    let inputs: [ActionInput] = [
      .string("value"),
      .windowPlacement(.init(placement: .leftHalf)),
      .windowMove(.init(direction: .next)),
    ]

    for kind in ActionKind.allCases where kind.inputShape == .none {
      for input in inputs {
        XCTAssertNil(kind.action(input: input), "\(kind) should reject \(input)")
      }
    }
  }

  func testInputRequiringActionKindsRejectMismatchedInputShapes() {
    let sampleInputs: [ActionInputShape: ActionInput] = [
      .string: .string("value"),
      .windowPlacement: .windowPlacement(.init(placement: .leftHalf)),
      .windowMove: .windowMove(.init(direction: .next)),
    ]

    for kind in ActionKind.allCases where kind.inputShape != .none {
      for (shape, input) in sampleInputs where shape != kind.inputShape {
        XCTAssertNil(kind.action(input: input), "\(kind) should reject \(shape) input")
      }
    }
  }

  func testStringInputActionKindsRejectBlankInput() {
    for kind in ActionKind.allCases where kind.inputShape == .string {
      XCTAssertNil(kind.action(input: .string(" ")), "\(kind) should reject blank string input")
    }
  }

  func testStringInputActionKindsTrimInputValues() {
    for (kind, input, action) in ActionTestFixtures.inputActionCases {
      guard case .string(let value) = input else { continue }

      let createdAction = kind.action(input: .string("  \(value)\n"))

      XCTAssertEqual(createdAction, action)
      XCTAssertEqual(createdAction?.input, input)
    }
  }
}

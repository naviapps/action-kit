import XCTest

import ActionKit

final class ActionKindCreationTests: XCTestCase {
  func testMakeActionCoversActionKindsWithoutInput() {
    for kind in ActionKind.allCases {
      if kind.inputDescriptor.shape == .none {
        XCTAssertEqual(kind.makeAction()?.kind, kind)
      } else {
        XCTAssertNil(kind.makeAction())
      }
    }
  }

  func testMakeActionCreatesActionsForAllInputRequiringKinds() {
    let fixtures = ActionTestFixtures.inputActionCases
    let inputRequiringKinds = ActionKind.allCases.filter { $0.inputDescriptor.shape != .none }

    XCTAssertEqual(fixtures.count, inputRequiringKinds.count)
    XCTAssertEqual(Set(fixtures.map(\.kind)), Set(inputRequiringKinds))
    for (kind, input, action) in fixtures {
      XCTAssertEqual(kind.makeAction(input: input), action)
    }
  }

  func testInputDescriptorExamplesCreateMatchingActions() {
    for kind in ActionKind.allCases {
      let action: Action?
      if let exampleInput = kind.inputDescriptor.exampleInput {
        action = kind.makeAction(input: exampleInput)
      } else {
        action = kind.makeAction()
      }

      XCTAssertEqual(action?.kind, kind, "\(kind) descriptor example should create its action")
    }
  }

  func testInputFreeActionKindsRejectHostInput() {
    let inputs: [ActionInput] = [
      .string("value"),
      .windowPlacement(
        .init(placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))),
      .windowMove(.init(direction: .next)),
    ]

    for kind in ActionKind.allCases where kind.inputDescriptor.shape == .none {
      for input in inputs {
        XCTAssertNil(kind.makeAction(input: input), "\(kind) should reject \(input)")
      }
    }
  }

  func testInputRequiringActionKindsRejectMismatchedInputShapes() {
    let sampleInputs: [ActionInputShape: ActionInput] = [
      .string: .string("value"),
      .windowPlacement: .windowPlacement(
        .init(placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))),
      .windowMove: .windowMove(.init(direction: .next)),
    ]

    for kind in ActionKind.allCases where kind.inputDescriptor.shape != .none {
      for (shape, input) in sampleInputs where shape != kind.inputDescriptor.shape {
        XCTAssertNil(kind.makeAction(input: input), "\(kind) should reject \(shape) input")
      }
    }
  }

  func testStringInputActionKindsRejectBlankInput() {
    for kind in ActionKind.allCases where kind.inputDescriptor.shape == .string {
      XCTAssertNil(kind.makeAction(input: .string(" ")), "\(kind) should reject blank string input")
    }
  }

  func testStringInputActionKindsTrimInputValues() {
    for (kind, input, action) in ActionTestFixtures.inputActionCases {
      guard case .string(let value) = input else { continue }

      let createdAction = kind.makeAction(input: .string("  \(value)\n"))

      XCTAssertEqual(createdAction, action)
      XCTAssertEqual(createdAction?.input, input)
    }
  }
}

import XCTest

import ActionKit

final class ActionCodingCoverageTests: XCTestCase {
  func testEncodesAndDecodesEveryActionKind() throws {
    let actions = ActionTestFixtures.actionKindCases.map(\.action)

    XCTAssertEqual(actions.count, ActionKind.allCases.count)
    XCTAssertEqual(Set(actions.map(\.kind)), Set(ActionKind.allCases))

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for action in actions {
      let data = try encoder.encode(action)
      let decoded = try decoder.decode(Action.self, from: data)
      XCTAssertEqual(decoded, action)
    }
  }
}

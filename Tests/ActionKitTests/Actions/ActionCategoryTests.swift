import XCTest

import ActionKit

final class ActionCategoryTests: XCTestCase {
  func testActionCategoriesRoundTripCodableRawValue() throws {
    for category in ActionCategory.allCases {
      let data = try JSONEncoder().encode(category)
      XCTAssertEqual(try JSONDecoder().decode(ActionCategory.self, from: data), category)
    }
  }

  func testActionCategoryRawValuesAreCanonical() {
    XCTAssertEqual(
      ActionCategory.allCases.map(\.rawValue),
      [
        "editing",
        "frontmost-application",
        "media",
        "keyboard",
        "workspace",
        "system",
        "window",
      ]
    )
  }
}

import XCTest

@testable import ActionKit

final class ActionCategoryTests: XCTestCase {
  func testActionCategoryCasesAreStable() {
    XCTAssertEqual(
      ActionCategory.allCases,
      [
        .editing,
        .frontmostApplication,
        .media,
        .keyboard,
        .workspace,
        .system,
        .window,
      ]
    )
  }

  func testActionCategoriesRoundTripCodableRawValue() throws {
    for category in ActionCategory.allCases {
      let data = try JSONEncoder().encode(category)
      XCTAssertEqual(try JSONDecoder().decode(ActionCategory.self, from: data), category)
    }
  }

  func testActionCategoryRawValuesAreStable() {
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

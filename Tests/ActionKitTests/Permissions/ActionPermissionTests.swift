import XCTest

import ActionKit

final class ActionPermissionTests: XCTestCase {
  func testPermissionRoundTripsCodableRawValue() throws {
    for permission in ActionPermission.allCases {
      let data = try JSONEncoder().encode(permission)
      XCTAssertEqual(try JSONDecoder().decode(ActionPermission.self, from: data), permission)
    }
  }

  func testPermissionRawValuesAreCanonical() {
    XCTAssertEqual(
      ActionPermission.allCases.map(\.rawValue),
      ["accessibility", "automation", "screen-recording"]
    )
  }

  func testPermissionIsHashable() {
    let permissions: Set<ActionPermission> = [
      .accessibility,
      .accessibility,
      .automation,
    ]

    XCTAssertEqual(permissions, [.accessibility, .automation])
  }
}

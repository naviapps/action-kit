import XCTest

import ActionKit

final class ActionPermissionSetTests: XCTestCase {
  func testPermissionSetRoundTripsCodableValues() throws {
    let set = ActionPermissionSet(
      primary: [.screenRecording, .automation, .accessibility],
      fallback: [.screenRecording, .accessibility]
    )

    let data = try JSONEncoder().encode(set)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let decoded = try JSONDecoder().decode(ActionPermissionSet.self, from: data)

    XCTAssertEqual(
      object?["primary"] as? [String],
      ["accessibility", "automation", "screen-recording"]
    )
    XCTAssertEqual(object?["fallback"] as? [String], ["accessibility", "screen-recording"])
    XCTAssertEqual(decoded.primary, [.accessibility, .automation, .screenRecording])
    XCTAssertEqual(decoded.fallback, [.accessibility, .screenRecording])
  }

  func testPermissionSetRejectsDuplicatePermissionsOnDecode() throws {
    let duplicatePrimary = """
      {
        "primary": ["accessibility", "accessibility"],
        "fallback": []
      }
      """.data(using: .utf8)!
    let duplicateFallback = """
      {
        "primary": [],
        "fallback": ["automation", "automation"]
      }
      """.data(using: .utf8)!

    assertPermissionSetDecodeRejects(duplicatePrimary, codingPath: ["primary"])
    assertPermissionSetDecodeRejects(duplicateFallback, codingPath: ["fallback"])
  }

  func testPermissionSetRejectsUnknownFieldsOnDecode() throws {
    let data = """
      {
        "primary": [],
        "fallback": [],
        "metadata": {}
      }
      """.data(using: .utf8)!

    assertPermissionSetDecodeRejects(data, codingPath: ["metadata"])
  }

  func testPermissionSetReportsFallbackOnlyPermissions() {
    let set = ActionPermissionSet(
      primary: [.accessibility],
      fallback: [.accessibility, .screenRecording]
    )

    XCTAssertEqual(set.fallbackOnly, [.screenRecording])
  }

  func testPermissionSetReportsAllPermissions() {
    let set = ActionPermissionSet(
      primary: [.accessibility, .automation],
      fallback: [.accessibility, .screenRecording]
    )

    XCTAssertEqual(set.all, [.accessibility, .automation, .screenRecording])
  }

  func testPermissionSetIsHashable() {
    let sets: Set<ActionPermissionSet> = [
      .init(primary: [.accessibility], fallback: [.automation]),
      .init(primary: [.accessibility], fallback: [.automation]),
      .init(primary: [.automation], fallback: [.accessibility]),
    ]

    XCTAssertEqual(sets.count, 2)
  }

  func testPermissionSetIsEmptyWhenPrimaryAndFallbackAreEmpty() {
    let set = ActionPermissionSet(primary: [], fallback: [])

    XCTAssertTrue(set.isEmpty)
  }

  private func assertPermissionSetDecodeRejects(
    _ data: Data,
    codingPath: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(ActionPermissionSet.self, from: data),
      file: file,
      line: line
    ) { error in
      guard case let DecodingError.dataCorrupted(context) = error else {
        return XCTFail("Expected dataCorrupted, got \(error)", file: file, line: line)
      }
      XCTAssertEqual(context.codingPath.map(\.stringValue), codingPath, file: file, line: line)
    }
  }
}

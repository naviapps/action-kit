import XCTest

@testable import ActionKit

final class ActionResultTests: XCTestCase {
  func testSkipReasonsRoundTripCodableRawValue() throws {
    for reason in ActionSkipReason.allCases {
      let data = try JSONEncoder().encode(reason)
      XCTAssertEqual(try JSONDecoder().decode(ActionSkipReason.self, from: data), reason)
    }
  }

  func testSkipReasonRawValuesAreStable() {
    XCTAssertEqual(
      ActionSkipReason.allCases.map(\.rawValue),
      [
        "no-frontmost-application",
        "no-focused-window",
      ]
    )
  }

  func testActionResultRoundTripsCodable() throws {
    let results: [ActionResult] = [
      .success,
      .skipped(.noFocusedWindow),
      .failure(.openFailed("failed to open")),
    ]

    for result in results {
      let data = try JSONEncoder().encode(result)
      XCTAssertEqual(try JSONDecoder().decode(ActionResult.self, from: data), result)
    }
  }

  func testActionResultUsesStableCodableShape() throws {
    let success = try encodedJSONObject(ActionResult.success)

    XCTAssertEqual(Set(success.keys), ["status"])
    XCTAssertEqual(success["status"] as? String, "success")

    let skipped = try encodedJSONObject(ActionResult.skipped(.noFocusedWindow))

    XCTAssertEqual(Set(skipped.keys), ["status", "skipReason"])
    XCTAssertEqual(skipped["status"] as? String, "skipped")
    XCTAssertEqual(skipped["skipReason"] as? String, "no-focused-window")

    let failed = try encodedJSONObject(ActionResult.failure(.openFailed("failed")))
    let error = failed["error"] as? [String: Any]

    XCTAssertEqual(Set(failed.keys), ["status", "error"])
    XCTAssertEqual(failed["status"] as? String, "failure")
    XCTAssertEqual(error?["code"] as? String, "open-failed")
  }

  func testActionResultDecodesStableCodableShape() throws {
    let success = Data(
      """
      {"status":"success"}
      """.utf8
    )
    let skipped = Data(
      """
      {"status":"skipped","skipReason":"no-focused-window"}
      """.utf8
    )
    let failure = Data(
      """
      {"status":"failure","error":{"code":"open-failed","diagnosticMessage":"failed"}}
      """.utf8
    )

    XCTAssertEqual(try JSONDecoder().decode(ActionResult.self, from: success), .success)
    XCTAssertEqual(
      try JSONDecoder().decode(ActionResult.self, from: skipped),
      .skipped(.noFocusedWindow)
    )
    XCTAssertEqual(
      try JSONDecoder().decode(ActionResult.self, from: failure),
      .failure(.openFailed("failed"))
    )
  }

  func testActionResultRequiresStatus() {
    let data = Data(
      """
      {"skipReason":"no-focused-window"}
      """.utf8
    )

    assertActionResultDecodeRequiresKey(data, key: "status", codingPath: [])
  }

  func testActionResultRejectsContradictoryCodableShape() {
    let successWithError = Data(
      """
      {"status":"success","error":{"code":"open-failed","diagnosticMessage":"failed"}}
      """.utf8
    )
    let successWithSkipReason = Data(
      """
      {"status":"success","skipReason":"no-focused-window"}
      """.utf8
    )
    let skippedWithError = Data(
      """
      {"status":"skipped","skipReason":"no-focused-window","error":{"code":"open-failed","diagnosticMessage":"failed"}}
      """.utf8
    )
    let failureWithSkipReason = Data(
      """
      {"status":"failure","skipReason":"no-focused-window","error":{"code":"open-failed","diagnosticMessage":"failed"}}
      """.utf8
    )

    assertActionResultDecodeRejects(successWithError, codingPath: ["error"])
    assertActionResultDecodeRejects(successWithSkipReason, codingPath: ["skipReason"])
    assertActionResultDecodeRejects(skippedWithError, codingPath: ["error"])
    assertActionResultDecodeRejects(failureWithSkipReason, codingPath: ["skipReason"])
  }

  func testActionResultRequiresAssociatedCodablePayloads() {
    let skippedWithoutReason = Data(
      """
      {"status":"skipped"}
      """.utf8
    )
    let failureWithoutError = Data(
      """
      {"status":"failure"}
      """.utf8
    )

    assertActionResultDecodeRequiresKey(
      skippedWithoutReason,
      key: "skipReason",
      codingPath: []
    )
    assertActionResultDecodeRequiresKey(
      failureWithoutError,
      key: "error",
      codingPath: []
    )
  }

  private func assertActionResultDecodeRejects(
    _ data: Data,
    codingPath: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(ActionResult.self, from: data),
      file: file,
      line: line
    ) { error in
      guard case let DecodingError.dataCorrupted(context) = error else {
        return XCTFail("Expected dataCorrupted, got \(error)", file: file, line: line)
      }
      XCTAssertEqual(context.codingPath.map(\.stringValue), codingPath, file: file, line: line)
    }
  }

  private func encodedJSONObject(
    _ result: ActionResult,
    file: StaticString = #filePath,
    line: UInt = #line
  ) throws -> [String: Any] {
    let object = try JSONSerialization.jsonObject(with: JSONEncoder().encode(result))
    guard let object = object as? [String: Any] else {
      XCTFail("Expected JSON object.", file: file, line: line)
      return [:]
    }
    return object
  }

  private func assertActionResultDecodeRequiresKey(
    _ data: Data,
    key expectedKey: String,
    codingPath: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(ActionResult.self, from: data),
      file: file,
      line: line
    ) { error in
      guard case let DecodingError.keyNotFound(key, context) = error else {
        return XCTFail("Expected keyNotFound, got \(error)", file: file, line: line)
      }
      XCTAssertEqual(key.stringValue, expectedKey, file: file, line: line)
      XCTAssertEqual(context.codingPath.map(\.stringValue), codingPath, file: file, line: line)
    }
  }
}

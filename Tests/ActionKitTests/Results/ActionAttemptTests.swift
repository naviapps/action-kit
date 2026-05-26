import XCTest

@testable import ActionKit

final class ActionAttemptTests: XCTestCase {
  func testActionAttemptInitializerPreservesPublicProperties() {
    let attempt = ActionAttempt(
      requiredPermissions: [.accessibility, .automation],
      isFallback: true,
      result: .skipped(.noFocusedWindow),
      duration: .milliseconds(250)
    )

    XCTAssertEqual(attempt.requiredPermissions, [.accessibility, .automation])
    XCTAssertTrue(attempt.isFallback)
    XCTAssertEqual(attempt.result, .skipped(.noFocusedWindow))
    XCTAssertEqual(attempt.duration, .milliseconds(250))
  }

  func testActionAttemptStepInitializerPreservesStepMetadata() {
    let step = ActionStep(
      method: .keyEvent(virtualKeyCode: 36),
      requiredPermissions: [.accessibility],
      isFallback: true
    )
    let attempt = ActionAttempt(
      step: step,
      result: .success,
      duration: .milliseconds(250)
    )

    XCTAssertEqual(attempt.requiredPermissions, [.accessibility])
    XCTAssertTrue(attempt.isFallback)
    XCTAssertEqual(attempt.result, .success)
    XCTAssertEqual(attempt.duration, .milliseconds(250))
  }

  func testActionAttemptUsesStableCodableShape() throws {
    let attempt = ActionAttempt(
      requiredPermissions: [.accessibility],
      isFallback: true,
      result: .success,
      duration: .milliseconds(250)
    )

    let data = try JSONEncoder().encode(attempt)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let result = object?["result"] as? [String: Any]

    XCTAssertEqual(object?["requiredPermissions"] as? [String], ["accessibility"])
    XCTAssertEqual(object?["isFallback"] as? Bool, true)
    XCTAssertEqual(result?["status"] as? String, "success")
    XCTAssertEqual(object?["durationSeconds"] as? Double, 0.25)
    XCTAssertNil(object?["duration"])
  }

  func testActionAttemptDecodesStableCodableShape() throws {
    let data = """
      {
        "requiredPermissions": ["accessibility"],
        "isFallback": true,
        "result": { "status": "skipped", "skipReason": "no-focused-window" },
        "durationSeconds": 0.25
      }
      """.data(using: .utf8)!

    let attempt = try JSONDecoder().decode(ActionAttempt.self, from: data)

    XCTAssertEqual(attempt.requiredPermissions, [.accessibility])
    XCTAssertTrue(attempt.isFallback)
    XCTAssertEqual(attempt.result, .skipped(.noFocusedWindow))
    XCTAssertEqual(attempt.duration, .milliseconds(250))
  }

  func testActionAttemptRejectsNegativeDurationSecondsOnDecode() throws {
    let data = """
      {
        "requiredPermissions": [],
        "isFallback": false,
        "result": { "status": "success" },
        "durationSeconds": -1
      }
      """.data(using: .utf8)!

    assertActionAttemptDecodeRejects(data, codingPath: ["durationSeconds"])
  }

  func testActionAttemptRejectsDurationSecondsOutsideInt64Range() throws {
    let data = """
      {
        "requiredPermissions": [],
        "isFallback": false,
        "result": { "status": "success" },
        "durationSeconds": 9223372036854775808
      }
      """.data(using: .utf8)!

    assertActionAttemptDecodeRejects(data, codingPath: ["durationSeconds"])
  }

  func testActionAttemptEncodesPermissionsInStableOrder() throws {
    let attempt = ActionAttempt(
      requiredPermissions: [.screenRecording, .automation, .accessibility],
      isFallback: false,
      result: .success
    )

    let data = try JSONEncoder().encode(attempt)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(
      object?["requiredPermissions"] as? [String],
      ["accessibility", "automation", "screen-recording"]
    )
  }

  func testActionAttemptRoundTripsFractionalDurationSeconds() throws {
    let attempt = ActionAttempt(
      requiredPermissions: [],
      isFallback: false,
      result: .success,
      duration: .milliseconds(250)
    )

    let data = try JSONEncoder().encode(attempt)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(object?["durationSeconds"] as? Double, 0.25)
    XCTAssertEqual(try JSONDecoder().decode(ActionAttempt.self, from: data), attempt)
  }

  func testActionAttemptRejectsNegativeDurationOnEncode() {
    let attempt = ActionAttempt(
      requiredPermissions: [],
      isFallback: false,
      result: .success,
      duration: Duration(secondsComponent: -1, attosecondsComponent: 0)
    )

    assertActionAttemptEncodeRejects(attempt, codingPath: ["durationSeconds"])
  }

  func testActionAttemptRejectsNonRoundTrippableDurationOnEncode() {
    let attempt = ActionAttempt(
      requiredPermissions: [],
      isFallback: false,
      result: .success,
      duration: Duration(secondsComponent: Int64.max, attosecondsComponent: 0)
    )

    assertActionAttemptEncodeRejects(attempt, codingPath: ["durationSeconds"])
  }

  func testActionAttemptOmitsDurationSecondsWhenDurationIsNil() throws {
    let attempt = ActionAttempt(
      requiredPermissions: [],
      isFallback: false,
      result: .success
    )

    let data = try JSONEncoder().encode(attempt)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertNil(object?["durationSeconds"])
  }

  func testActionAttemptRequiresRequiredCodableFields() {
    let missingRequiredPermissions = Data(
      """
      {"isFallback":false,"result":{"status":"success"}}
      """.utf8
    )
    let missingFallbackFlag = Data(
      """
      {"requiredPermissions":[],"result":{"status":"success"}}
      """.utf8
    )
    let missingResult = Data(
      """
      {"requiredPermissions":[],"isFallback":false}
      """.utf8
    )

    assertActionAttemptDecodeRequiresKey(
      missingRequiredPermissions,
      key: "requiredPermissions",
      codingPath: []
    )
    assertActionAttemptDecodeRequiresKey(
      missingFallbackFlag,
      key: "isFallback",
      codingPath: []
    )
    assertActionAttemptDecodeRequiresKey(missingResult, key: "result", codingPath: [])
  }

  private func assertActionAttemptDecodeRejects(
    _ data: Data,
    codingPath: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(ActionAttempt.self, from: data),
      file: file,
      line: line
    ) { error in
      guard case let DecodingError.dataCorrupted(context) = error else {
        return XCTFail("Expected dataCorrupted, got \(error)", file: file, line: line)
      }
      XCTAssertEqual(context.codingPath.map(\.stringValue), codingPath, file: file, line: line)
    }
  }

  private func assertActionAttemptDecodeRequiresKey(
    _ data: Data,
    key expectedKey: String,
    codingPath: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(ActionAttempt.self, from: data),
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

  private func assertActionAttemptEncodeRejects(
    _ attempt: ActionAttempt,
    codingPath: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(try JSONEncoder().encode(attempt), file: file, line: line) { error in
      guard case let EncodingError.invalidValue(_, context) = error else {
        return XCTFail("Expected invalidValue, got \(error)", file: file, line: line)
      }
      XCTAssertEqual(context.codingPath.map(\.stringValue), codingPath, file: file, line: line)
    }
  }
}

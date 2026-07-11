import XCTest

import ActionKit

final class ActionOutcomeTests: XCTestCase {
  func testOutcomeExposesDerivedConvenienceValues() {
    let attempt = successfulAttempt()
    let outcome = ActionOutcome(attempts: [attempt])

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(outcome.successfulAttempt, attempt)
    XCTAssertFalse(outcome.didAttemptFallback)
  }

  func testOutcomeDetectsFallbackAttempts() {
    let outcome = ActionOutcome(attempts: [successfulAttempt(isFallback: true)])

    XCTAssertTrue(outcome.didAttemptFallback)
    XCTAssertEqual(outcome.successfulAttempt?.isFallback, true)
  }

  func testOutcomeFallbackDetectionDoesNotRequireFallbackSuccess() {
    let outcome = ActionOutcome(
      attempts: [
        failedAttempt(.notFound("missing")),
        failedAttempt(
          .internalError("fallback failed"),
          requiredPermissions: [.accessibility],
          isFallback: true
        ),
      ]
    )

    XCTAssertNil(outcome.successfulAttempt)
    XCTAssertEqual(outcome.finalResult, .failure(.internalError("fallback failed")))
    XCTAssertTrue(outcome.didAttemptFallback)
  }

  func testOutcomeTreatsSkippedAttemptsAsUnsuccessful() {
    let outcome = ActionOutcome(attempts: [skippedAttempt(.noFocusedWindow)])

    XCTAssertNil(outcome.successfulAttempt)
    XCTAssertEqual(outcome.finalResult, .skipped(.noFocusedWindow))
    XCTAssertFalse(outcome.didAttemptFallback)
  }

  func testOutcomeUsesLastSuccessfulAttempt() {
    let firstSuccess = successfulAttempt()
    let laterSuccess = successfulAttempt(requiredPermissions: [.accessibility], isFallback: true)
    let outcome = ActionOutcome(
      attempts: [
        firstSuccess,
        failedAttempt(.notFound("missing")),
        laterSuccess,
      ]
    )

    XCTAssertEqual(outcome.successfulAttempt, laterSuccess)
    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertTrue(outcome.didAttemptFallback)
  }

  func testOutcomeWithoutAttemptsRecordsInternalErrorAttempt() throws {
    let outcome = ActionOutcome(attempts: [])

    XCTAssertEqual(outcome.attempts.count, 1)
    XCTAssertEqual(outcome.attempts.first?.requiredPermissions, [])
    XCTAssertFalse(outcome.attempts.first?.isFallback ?? true)
    XCTAssertEqual(outcome.attempts.first?.result, outcome.finalResult)
    XCTAssertNil(outcome.successfulAttempt)
    XCTAssertFalse(outcome.didAttemptFallback)
    XCTAssertEqual(
      outcome.finalResult,
      .failure(.internalError("No execution attempts were recorded"))
    )
  }

  func testOutcomeRejectsEmptyAttemptPayloadsOnDecode() throws {
    let data = """
      {
        "finalResult": {
          "status": "failure",
          "error": {
            "code": "internal-error",
            "diagnosticMessage": "No execution attempts were recorded"
          }
        },
        "attempts": []
      }
      """.data(using: .utf8)!

    assertActionOutcomeDecodeRejects(data, codingPath: ["attempts"])
  }

  func testOutcomeEncodesDerivedFinalResultAndRoundTrips() throws {
    let outcome = ActionOutcome(
      attempts: [
        successfulAttempt(),
        failedAttempt(.permissionDenied(.accessibility), requiredPermissions: [.accessibility]),
      ]
    )

    let data = try JSONEncoder().encode(outcome)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let finalResult = object?["finalResult"] as? [String: Any]
    let attempts = object?["attempts"] as? [[String: Any]]

    XCTAssertEqual(finalResult?["status"] as? String, "failure")
    XCTAssertEqual(attempts?.count, 2)
    XCTAssertEqual(try JSONDecoder().decode(ActionOutcome.self, from: data), outcome)
  }

  func testOutcomeRejectsFinalResultThatConflictsWithAttempts() throws {
    let data = """
      {
        "finalResult": { "status": "success" },
        "attempts": [
          {
            "requiredPermissions": [],
            "isFallback": false,
            "result": {
              "status": "failure",
              "error": {
                "code": "not-found",
                "diagnosticMessage": "missing"
              }
            }
          }
        ]
      }
      """.data(using: .utf8)!

    assertActionOutcomeDecodeRejects(data, codingPath: ["finalResult"])
  }

  func testOutcomeRejectsUnknownFields() throws {
    let data = """
      {
        "finalResult": { "status": "success" },
        "attempts": [
          {
            "requiredPermissions": [],
            "isFallback": false,
            "result": { "status": "success" }
          }
        ],
        "metadata": {}
      }
      """.data(using: .utf8)!

    assertActionOutcomeDecodeRejects(data, codingPath: ["metadata"])
  }

  private func successfulAttempt(
    requiredPermissions: Set<ActionPermission> = [],
    isFallback: Bool = false
  ) -> ActionAttempt {
    ActionAttempt(
      requiredPermissions: requiredPermissions,
      isFallback: isFallback,
      result: .success
    )
  }

  private func skippedAttempt(
    _ reason: ActionSkipReason,
    requiredPermissions: Set<ActionPermission> = [],
    isFallback: Bool = false
  ) -> ActionAttempt {
    ActionAttempt(
      requiredPermissions: requiredPermissions,
      isFallback: isFallback,
      result: .skipped(reason)
    )
  }

  private func failedAttempt(
    _ error: ActionError,
    requiredPermissions: Set<ActionPermission> = [],
    isFallback: Bool = false
  ) -> ActionAttempt {
    ActionAttempt(
      requiredPermissions: requiredPermissions,
      isFallback: isFallback,
      result: .failure(error)
    )
  }

  private func assertActionOutcomeDecodeRejects(
    _ data: Data,
    codingPath: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(ActionOutcome.self, from: data),
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

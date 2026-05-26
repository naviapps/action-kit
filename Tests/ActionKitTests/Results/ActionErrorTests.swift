import XCTest

@testable import ActionKit

final class ActionErrorTests: XCTestCase {
  func testErrorCodesRoundTripCodableRawValue() throws {
    for code in ActionErrorCode.allCases {
      let data = try JSONEncoder().encode(code)
      XCTAssertEqual(try JSONDecoder().decode(ActionErrorCode.self, from: data), code)
    }
  }

  func testErrorCodeRawValuesAreStable() {
    XCTAssertEqual(
      ActionErrorCode.allCases.map(\.rawValue),
      [
        "invalid-input",
        "permission-denied",
        "not-found",
        "open-failed",
        "apple-script-failed",
        "screen-capture-failed",
        "internal-error",
      ]
    )
  }

  func testAutomationPermissionDeniedUsesStableCodableShape() throws {
    let error = ActionError.automationPermissionDenied(appleScriptErrorNumber: -1743)
    let data = try JSONEncoder().encode(error)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(object?["code"] as? String, "permission-denied")
    XCTAssertEqual(
      object?["diagnosticMessage"] as? String,
      "Permission denied: automation (AppleScript error number -1743)"
    )
    XCTAssertEqual(object?["permission"] as? String, "automation")
    XCTAssertEqual(object?["appleScriptErrorNumber"] as? Int, -1743)
    XCTAssertNil(object?["message"])
    XCTAssertNil(object?["debugDescription"])
    XCTAssertEqual(try JSONDecoder().decode(ActionError.self, from: data), error)
  }

  func testAppleScriptFailureUsesStableCodableShape() throws {
    let error = ActionError.appleScriptFailed(
      "The variable bad is not defined. (AppleScript error number 42)",
      appleScriptErrorNumber: 42
    )
    let data = try JSONEncoder().encode(error)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(object?["code"] as? String, "apple-script-failed")
    XCTAssertEqual(
      object?["diagnosticMessage"] as? String,
      "The variable bad is not defined. (AppleScript error number 42)"
    )
    XCTAssertEqual(object?["appleScriptErrorNumber"] as? Int, 42)
    XCTAssertNil(object?["permission"])
    XCTAssertEqual(try JSONDecoder().decode(ActionError.self, from: data), error)
  }

  func testActionErrorUsesDiagnosticMessageAsLocalizedDescription() {
    let error = ActionError.openFailed("Failed to open URL")

    XCTAssertEqual(error.errorDescription, "Failed to open URL")
    XCTAssertEqual(error.localizedDescription, "Failed to open URL")
  }

  func testActionErrorFactoryMethodsNormalizeDiagnosticMessages() {
    XCTAssertEqual(ActionError.invalidInput("  bad  ").diagnosticMessage, "bad")
    XCTAssertEqual(ActionError.invalidInput("  ").diagnosticMessage, "Invalid input")
    XCTAssertEqual(ActionError.notFound("  ").diagnosticMessage, "Not found")
    XCTAssertEqual(ActionError.openFailed("  ").diagnosticMessage, "Open failed")
    XCTAssertEqual(ActionError.appleScriptFailed("  ").diagnosticMessage, "AppleScript failed")
    XCTAssertEqual(
      ActionError.appleScriptFailed("  ", appleScriptErrorNumber: 42).diagnosticMessage,
      "AppleScript failed (AppleScript error number 42)"
    )
    XCTAssertEqual(
      ActionError.screenCaptureFailed("  ").diagnosticMessage,
      "Screen capture failed"
    )
    XCTAssertEqual(ActionError.internalError("  ").diagnosticMessage, "Internal error")
  }

  func testActionErrorRejectsBlankDiagnosticMessage() throws {
    let data = """
      {
        "code": "open-failed",
        "diagnosticMessage": "   "
      }
      """.data(using: .utf8)!

    assertActionErrorDecodeRejects(data, codingPath: ["diagnosticMessage"])
  }

  func testActionErrorRejectsPermissionDeniedWithoutPermission() throws {
    let data = """
      {
        "code": "permission-denied",
        "diagnosticMessage": "Permission denied"
      }
      """.data(using: .utf8)!

    assertActionErrorDecodeRejects(data, codingPath: ["permission"])
  }

  func testActionErrorRejectsPermissionForNonPermissionCode() throws {
    let data = """
      {
        "code": "not-found",
        "diagnosticMessage": "Missing",
        "permission": "automation"
      }
      """.data(using: .utf8)!

    assertActionErrorDecodeRejects(data, codingPath: ["permission"])
  }

  func testActionErrorRejectsPermissionForAppleScriptFailure() throws {
    let data = """
      {
        "code": "apple-script-failed",
        "diagnosticMessage": "Failed",
        "permission": "automation"
      }
      """.data(using: .utf8)!

    assertActionErrorDecodeRejects(data, codingPath: ["permission"])
  }

  func testActionErrorRejectsAppleScriptNumberForUnrelatedCode() throws {
    let data = """
      {
        "code": "screen-capture-failed",
        "diagnosticMessage": "Failed",
        "appleScriptErrorNumber": -1
      }
      """.data(using: .utf8)!

    assertActionErrorDecodeRejects(data, codingPath: ["appleScriptErrorNumber"])
  }

  func testActionErrorRejectsAppleScriptNumberForNonAutomationPermission() throws {
    let data = """
      {
        "code": "permission-denied",
        "diagnosticMessage": "Permission denied",
        "permission": "accessibility",
        "appleScriptErrorNumber": -1743
      }
      """.data(using: .utf8)!

    assertActionErrorDecodeRejects(data, codingPath: ["appleScriptErrorNumber"])
  }

  func testFactoryMethodsSetErrorCodes() {
    let cases: [(error: ActionError, code: ActionErrorCode)] = [
      (.invalidInput("bad"), .invalidInput),
      (.notFound("missing"), .notFound),
      (.openFailed("fail"), .openFailed),
      (.permissionDenied(.accessibility), .permissionDenied),
      (.automationPermissionDenied(), .permissionDenied),
      (.appleScriptFailed("nope"), .appleScriptFailed),
      (.screenCaptureFailed("capture failed"), .screenCaptureFailed),
      (.internalError("oops"), .internalError),
    ]

    for expectation in cases {
      XCTAssertEqual(expectation.error.code, expectation.code)
    }
  }

  func testPermissionDeniedFactoryMethodsSetPermissionPayloads() {
    let permissionError = ActionError.permissionDenied(.automation)
    XCTAssertEqual(permissionError.code, .permissionDenied)
    XCTAssertEqual(permissionError.permission, .automation)
    XCTAssertNil(permissionError.appleScriptErrorNumber)

    let automationError = ActionError.automationPermissionDenied(appleScriptErrorNumber: 600)
    XCTAssertEqual(automationError.code, .permissionDenied)
    XCTAssertEqual(
      automationError.diagnosticMessage,
      "Permission denied: automation (AppleScript error number 600)"
    )
    XCTAssertEqual(automationError.permission, .automation)
    XCTAssertEqual(automationError.appleScriptErrorNumber, 600)

    let automationErrorWithoutNumber = ActionError.automationPermissionDenied()
    XCTAssertEqual(automationErrorWithoutNumber.code, .permissionDenied)
    XCTAssertEqual(automationErrorWithoutNumber.diagnosticMessage, "Permission denied: automation")
    XCTAssertEqual(automationErrorWithoutNumber.permission, .automation)
    XCTAssertNil(automationErrorWithoutNumber.appleScriptErrorNumber)

    let accessibilityError = ActionError.permissionDenied(.accessibility)
    XCTAssertEqual(accessibilityError.code, .permissionDenied)
    XCTAssertEqual(accessibilityError.permission, .accessibility)
    XCTAssertNil(accessibilityError.appleScriptErrorNumber)
  }

  func testAppleScriptFailureFactoryMethodsSetAppleScriptErrorNumber() {
    let scriptError = ActionError.appleScriptFailed("nope", appleScriptErrorNumber: -1)
    XCTAssertEqual(scriptError.code, .appleScriptFailed)
    XCTAssertEqual(scriptError.diagnosticMessage, "nope (AppleScript error number -1)")
    XCTAssertEqual(scriptError.appleScriptErrorNumber, -1)

    let scriptErrorWithNumberInMessage = ActionError.appleScriptFailed(
      "nope (AppleScript error number -1)",
      appleScriptErrorNumber: -1
    )
    XCTAssertEqual(
      scriptErrorWithNumberInMessage.diagnosticMessage,
      "nope (AppleScript error number -1)"
    )
    XCTAssertEqual(scriptErrorWithNumberInMessage.appleScriptErrorNumber, -1)

    let scriptErrorWithoutNumber = ActionError.appleScriptFailed("nope")
    XCTAssertEqual(scriptErrorWithoutNumber.code, .appleScriptFailed)
    XCTAssertEqual(scriptErrorWithoutNumber.diagnosticMessage, "nope")
    XCTAssertNil(scriptErrorWithoutNumber.appleScriptErrorNumber)
  }

  private func assertActionErrorDecodeRejects(
    _ data: Data,
    codingPath: [String],
    file: StaticString = #filePath,
    line: UInt = #line
  ) {
    XCTAssertThrowsError(
      try JSONDecoder().decode(ActionError.self, from: data),
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

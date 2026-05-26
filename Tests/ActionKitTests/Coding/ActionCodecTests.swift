import XCTest

@testable import ActionKit

final class ActionCodecTests: XCTestCase {
  func testCurrentVersionMatchesEncodedEnvelopeVersion() throws {
    let data = try ActionCodec.encode(.copy)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(ActionCodec.currentVersion, 1)
    XCTAssertEqual(object?["version"] as? Int, ActionCodec.currentVersion)
  }

  func testEncodeUsesVersionedEnvelopeShape() throws {
    let data = try ActionCodec.encode(.openURL("https://example.com"))
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let action = object?["action"] as? [String: Any]

    XCTAssertEqual(object?["version"] as? Int, ActionCodec.currentVersion)
    XCTAssertEqual(action?["kind"] as? String, "action.workspace.open-url")
    XCTAssertEqual(action?["input"] as? String, "https://example.com")
  }

  func testEncodeDecodeRoundTrip() throws {
    let action = Action.keyboardShortcut("cmd+shift+k")
    let data = try ActionCodec.encode(action)
    let decoded = try ActionCodec.decode(data)
    XCTAssertEqual(decoded, action)
  }

  func testDecodeRejectsUnsupportedVersionWithoutReadingActionPayload() {
    let data = Data(
      """
      {"version":999}
      """.utf8
    )

    XCTAssertThrowsError(try ActionCodec.decode(data)) { error in
      XCTAssertEqual(error as? ActionCodecError, .unsupportedVersion(999))
    }
  }

  func testActionCodecErrorDescribesUnsupportedVersion() {
    XCTAssertEqual(
      ActionCodecError.unsupportedVersion(999).localizedDescription,
      "Unsupported action envelope version: 999."
    )
  }

  func testActionCodecErrorIsHashable() {
    XCTAssertEqual(
      Set([
        ActionCodecError.unsupportedVersion(999),
        ActionCodecError.unsupportedVersion(999),
      ]).count,
      1
    )
  }
}

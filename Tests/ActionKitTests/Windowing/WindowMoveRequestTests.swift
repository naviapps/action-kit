import XCTest

import ActionKit

final class WindowMoveRequestTests: XCTestCase {
  func testPreservesRelativePositionByDefault() {
    let request = WindowMoveRequest(direction: .next)

    XCTAssertTrue(request.preservesRelativePosition)
  }

  func testRoundTripsCodable() throws {
    let request = WindowMoveRequest(direction: .previous, preservesRelativePosition: false)

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    XCTAssertEqual(
      try decoder.decode(WindowMoveRequest.self, from: encoder.encode(request)),
      request
    )
  }

  func testUsesCanonicalCodableKeys() throws {
    let object = try encodedObject(WindowMoveRequest(direction: .next))

    XCTAssertEqual(Set(object.keys), ["direction", "preservesRelativePosition"])
    XCTAssertEqual(object["direction"] as? String, "next")
    XCTAssertEqual(object["preservesRelativePosition"] as? Bool, true)
  }

  func testEncodesCanonicalDirections() throws {
    let cases: [(ActionWindowScreenCycleDirection, String)] = [
      (.next, "next"),
      (.previous, "previous"),
    ]

    for (direction, expectedValue) in cases {
      let object = try encodedObject(WindowMoveRequest(direction: direction))

      XCTAssertEqual(object["direction"] as? String, expectedValue)
    }
  }

  func testDecodesCanonicalDirections() throws {
    XCTAssertEqual(
      try decodedRequest(direction: "next"),
      WindowMoveRequest(direction: .next)
    )
    XCTAssertEqual(
      try decodedRequest(direction: "previous"),
      WindowMoveRequest(direction: .previous)
    )
  }

  func testDecodesCanonicalCodablePayload() throws {
    let data = Data(
      """
      {
        "direction": "previous",
        "preservesRelativePosition": false
      }
      """.utf8
    )

    XCTAssertEqual(
      try JSONDecoder().decode(WindowMoveRequest.self, from: data),
      WindowMoveRequest(direction: .previous, preservesRelativePosition: false)
    )
  }

  func testDecodingUsesRelativePositionDefaultWhenOmitted() throws {
    let data = Data(#"{"direction":"next"}"#.utf8)

    XCTAssertEqual(
      try JSONDecoder().decode(WindowMoveRequest.self, from: data),
      WindowMoveRequest(direction: .next)
    )
  }

  func testDecodingRejectsNullRelativePosition() {
    let data = Data(#"{"direction":"next","preservesRelativePosition":null}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(WindowMoveRequest.self, from: data))
  }

  func testDecodingRejectsUnknownFields() {
    let data = Data(
      """
      {
        "direction": "next",
        "preservesRelativePosition": true,
        "metadata": {}
      }
      """.utf8
    )

    XCTAssertThrowsError(try JSONDecoder().decode(WindowMoveRequest.self, from: data))
  }

  func testDecodingRequiresDirection() {
    let data = Data(#"{"preservesRelativePosition":true}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(WindowMoveRequest.self, from: data))
  }

  private func encodedObject(_ request: WindowMoveRequest) throws -> [String: Any] {
    let data = try JSONEncoder().encode(request)
    return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  private func decodedRequest(
    direction: String,
    preservesRelativePosition: Bool = true
  ) throws -> WindowMoveRequest {
    let data = try JSONSerialization.data(
      withJSONObject: [
        "direction": direction,
        "preservesRelativePosition": preservesRelativePosition,
      ]
    )
    return try JSONDecoder().decode(WindowMoveRequest.self, from: data)
  }
}

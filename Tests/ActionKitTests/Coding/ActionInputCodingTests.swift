import XCTest

import ActionKit

final class ActionInputCodingTests: XCTestCase {
  func testActionInputRoundTripsCodable() throws {
    let inputs = Self.inputFixtures
    let expectedShapes = ActionInputShape.allCases.filter { $0 != .none }

    XCTAssertEqual(inputs.count, expectedShapes.count)
    XCTAssertEqual(Set(inputs.map(\.shape)), Set(expectedShapes))

    for input in inputs {
      let data = try JSONEncoder().encode(input)

      XCTAssertEqual(try JSONDecoder().decode(ActionInput.self, from: data), input)
    }
  }

  func testActionInputUsesCanonicalCodableShape() throws {
    let input = ActionInput.string("  https://example.com  ")
    let data = try JSONEncoder().encode(input)
    let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]

    XCTAssertEqual(payload?["shape"] as? String, "string")
    XCTAssertEqual(payload?["value"] as? String, "https://example.com")
  }

  func testActionInputDecodesTrimmedString() throws {
    let data = Data(#"{"shape":"string","value":"  https://example.com  "}"#.utf8)

    XCTAssertEqual(
      try JSONDecoder().decode(ActionInput.self, from: data),
      .string("https://example.com")
    )
  }

  func testWindowPlacementInputUsesCanonicalCodableShape() throws {
    let input = ActionInput.windowPlacement(
      .init(placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1)))
    let data = try JSONEncoder().encode(input)
    let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let value = payload?["value"] as? [String: Any]
    let placement = value?["placement"] as? [String: Any]
    let screen = value?["screen"] as? [String: Any]

    XCTAssertEqual(payload?["shape"] as? String, "window-placement")
    XCTAssertEqual(placement?["kind"] as? String, "grid")
    XCTAssertEqual(placement?["columns"] as? Int, 2)
    XCTAssertEqual(placement?["rows"] as? Int, 1)
    XCTAssertEqual(placement?["column"] as? Int, 0)
    XCTAssertEqual(placement?["row"] as? Int, 0)
    XCTAssertEqual(placement?["columnSpan"] as? Int, 1)
    XCTAssertEqual(placement?["rowSpan"] as? Int, 1)
    XCTAssertEqual(screen?["kind"] as? String, "containing-window")
    XCTAssertEqual(value?["area"] as? String, "visible")
    XCTAssertEqual(value?["inset"] as? Double, 0)
  }

  func testWindowPlacementInputDecodesCanonicalCodableShape() throws {
    let data = Data(
      #"""
      {
        "shape": "window-placement",
        "value": {
          "placement": {
            "kind": "grid",
            "columns": 2,
            "rows": 1,
            "column": 0,
            "row": 0,
            "columnSpan": 1,
            "rowSpan": 1
          },
          "screen": { "kind": "containing-window" },
          "area": "visible",
          "inset": 0
        }
      }
      """#.utf8
    )

    XCTAssertEqual(
      try JSONDecoder().decode(ActionInput.self, from: data),
      .windowPlacement(
        .init(placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1)))
    )
  }

  func testWindowMoveInputUsesCanonicalCodableShape() throws {
    let input = ActionInput.windowMove(.init(direction: .next, preservesRelativePosition: false))
    let data = try JSONEncoder().encode(input)
    let payload = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let value = payload?["value"] as? [String: Any]

    XCTAssertEqual(payload?["shape"] as? String, "window-move")
    XCTAssertEqual(value?["direction"] as? String, "next")
    XCTAssertEqual(value?["preservesRelativePosition"] as? Bool, false)
  }

  func testWindowMoveInputDecodesCanonicalCodableShape() throws {
    let data = Data(
      #"""
      {
        "shape": "window-move",
        "value": {
          "direction": "next",
          "preservesRelativePosition": false
        }
      }
      """#.utf8
    )

    XCTAssertEqual(
      try JSONDecoder().decode(ActionInput.self, from: data),
      .windowMove(.init(direction: .next, preservesRelativePosition: false))
    )
  }

  func testActionInputRejectsInputFreeShape() {
    let data = Data(#"{"shape":"none"}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInput.self, from: data)) { error in
      guard case DecodingError.dataCorrupted(let context) = error else {
        XCTFail("Expected dataCorrupted, got \(error)")
        return
      }

      XCTAssertEqual(context.codingPath.map(\.stringValue), ["shape"])
    }
  }

  func testActionInputRejectsBlankStringOnDecode() {
    let data = Data(#"{"shape":"string","value":"  "}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInput.self, from: data)) { error in
      guard case DecodingError.dataCorrupted(let context) = error else {
        XCTFail("Expected dataCorrupted, got \(error)")
        return
      }

      XCTAssertEqual(context.codingPath.map(\.stringValue), ["value"])
    }
  }

  func testActionInputRejectsUnknownFields() {
    let data = Data(#"{"shape":"string","value":"value","metadata":{}}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(ActionInput.self, from: data))
  }

  func testActionInputRejectsBlankStringOnEncode() {
    XCTAssertThrowsError(try JSONEncoder().encode(ActionInput.string("  "))) { error in
      guard case EncodingError.invalidValue = error else {
        XCTFail("Expected invalidValue, got \(error)")
        return
      }
    }
  }

  private static var inputFixtures: [ActionInput] {
    [
      .string("https://example.com"),
      .windowPlacement(
        .init(placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))),
      .windowMove(.init(direction: .next)),
    ]
  }
}

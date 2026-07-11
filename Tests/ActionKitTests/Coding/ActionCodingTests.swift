import Foundation
import XCTest

import ActionKit

final class ActionCodingTests: XCTestCase {
  func testEncodesWithKindKey() throws {
    let data = try JSONEncoder().encode(Action.copy)
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(object?["kind"] as? String, "action.editing.copy")
    XCTAssertNil(object?["input"])
  }

  func testEncodesInputForStringInputActions() throws {
    let data = try JSONEncoder().encode(Action.openURL("  https://example.com  "))
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    XCTAssertEqual(object?["kind"] as? String, "action.workspace.open-url")
    XCTAssertEqual(object?["input"] as? String, "https://example.com")
  }

  func testEncodesInputForWindowPlacementActions() throws {
    let request = WindowPlacementRequest(
      placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1))
    let data = try JSONEncoder().encode(Action.windowPlacement(request))
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let input = object?["input"] as? [String: Any]
    let placement = input?["placement"] as? [String: Any]
    let screen = input?["screen"] as? [String: Any]

    XCTAssertEqual(object?["kind"] as? String, "action.window.placement")
    XCTAssertEqual(placement?["kind"] as? String, "grid")
    XCTAssertEqual(placement?["columns"] as? Int, 2)
    XCTAssertEqual(placement?["rows"] as? Int, 1)
    XCTAssertEqual(placement?["column"] as? Int, 0)
    XCTAssertEqual(placement?["row"] as? Int, 0)
    XCTAssertEqual(placement?["columnSpan"] as? Int, 1)
    XCTAssertEqual(placement?["rowSpan"] as? Int, 1)
    XCTAssertEqual(screen?["kind"] as? String, "containing-window")
    XCTAssertEqual(input?["area"] as? String, "visible")
    XCTAssertEqual(input?["inset"] as? Double, 0)
  }

  func testEncodesInputForWindowMoveActions() throws {
    let request = WindowMoveRequest(direction: .next, preservesRelativePosition: false)
    let data = try JSONEncoder().encode(Action.windowMove(request))
    let object = try JSONSerialization.jsonObject(with: data) as? [String: Any]
    let input = object?["input"] as? [String: Any]

    XCTAssertEqual(object?["kind"] as? String, "action.window.move")
    XCTAssertEqual(input?["direction"] as? String, "next")
    XCTAssertEqual(input?["preservesRelativePosition"] as? Bool, false)
  }

  func testEncodeRejectsBlankStringInput() {
    XCTAssertThrowsError(try JSONEncoder().encode(Action.openURL("  ")))
  }

  func testDecodesTrimmedStringInput() throws {
    let data = Data(#"{"kind":"action.workspace.open-url","input":"  https://example.com  "}"#.utf8)

    XCTAssertEqual(
      try JSONDecoder().decode(Action.self, from: data),
      .openURL("https://example.com")
    )
  }

  func testDecodeRejectsBlankStringInput() {
    let data = Data(#"{"kind":"action.workspace.open-url","input":"  "}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(Action.self, from: data))
  }

  func testDecodeRequiresInputForInputRequiringAction() {
    let data = Data(#"{"kind":"action.workspace.open-url"}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(Action.self, from: data))
  }

  func testDecodeRejectsNullInputForInputRequiringAction() {
    let data = Data(#"{"kind":"action.workspace.open-url","input":null}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(Action.self, from: data))
  }

  func testDecodeRejectsInputForInputFreeAction() {
    let data = Data(#"{"kind":"action.editing.copy","input":"unexpected"}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(Action.self, from: data))
  }

  func testDecodeRejectsUnknownActionFields() {
    let data = Data(#"{"kind":"action.editing.copy","metadata":{}}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(Action.self, from: data))
  }

  func testDecodeRejectsNullInputForInputFreeAction() {
    let data = Data(#"{"kind":"action.editing.copy","input":null}"#.utf8)

    XCTAssertThrowsError(try JSONDecoder().decode(Action.self, from: data))
  }
}

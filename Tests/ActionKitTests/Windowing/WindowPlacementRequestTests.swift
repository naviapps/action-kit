import WindowKit
import XCTest

@testable import ActionKit

final class WindowPlacementRequestTests: XCTestCase {
  func testUsesFocusedWindowDefaults() {
    let request = WindowPlacementRequest(placement: .leftHalf)

    XCTAssertEqual(request.screen, .containingWindow)
    XCTAssertEqual(request.area, .visible)
    XCTAssertEqual(request.inset, 0)
  }

  func testNormalizesInvalidInsets() {
    XCTAssertEqual(WindowPlacementRequest(placement: .leftHalf, inset: -1).inset, 0)
    XCTAssertEqual(WindowPlacementRequest(placement: .leftHalf, inset: .infinity).inset, 0)
    XCTAssertEqual(WindowPlacementRequest(placement: .leftHalf, inset: .nan).inset, 0)
  }

  func testRoundTripsCodable() throws {
    let requests = [
      WindowPlacementRequest(placement: .leftHalf),
      WindowPlacementRequest(
        placement: .grid(
          columns: 2,
          rows: 3,
          column: 1,
          row: 2,
          columnSpan: 1,
          rowSpan: 1
        ),
        screen: .orderedIndex(1),
        area: .full,
        inset: 8
      ),
      WindowPlacementRequest(
        placement: .centered(widthRatio: 0.7, heightRatio: 0.5),
        screen: .displayIdentifier(7),
        area: .full,
        inset: 12
      ),
      WindowPlacementRequest(
        placement: .rightTwoThirds,
        screen: .point(.init(x: 10, y: 20))
      ),
    ]

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for request in requests {
      XCTAssertEqual(
        try decoder.decode(WindowPlacementRequest.self, from: encoder.encode(request)),
        request
      )
    }
  }

  func testDecodingNormalizesInvalidInsets() throws {
    let encoded = try JSONEncoder().encode(WindowPlacementRequest(placement: .leftHalf))
    var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    payload["inset"] = -1
    let data = try JSONSerialization.data(withJSONObject: payload)

    let request = try JSONDecoder().decode(WindowPlacementRequest.self, from: data)

    XCTAssertEqual(request.inset, 0)
  }

  func testDecodingUsesFocusedWindowDefaultsWhenOptionalFieldsAreOmitted() throws {
    let encoded = try JSONEncoder().encode(WindowPlacementRequest(placement: .leftHalf))
    var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    payload.removeValue(forKey: "screen")
    payload.removeValue(forKey: "area")
    payload.removeValue(forKey: "inset")
    let data = try JSONSerialization.data(withJSONObject: payload)

    XCTAssertEqual(
      try JSONDecoder().decode(WindowPlacementRequest.self, from: data),
      WindowPlacementRequest(placement: .leftHalf)
    )
  }

  func testDecodingRejectsNullFocusedWindowDefaults() throws {
    let encoded = try JSONEncoder().encode(WindowPlacementRequest(placement: .leftHalf))

    for key in ["screen", "area", "inset"] {
      var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
      payload[key] = NSNull()
      let data = try JSONSerialization.data(withJSONObject: payload)

      XCTAssertThrowsError(
        try JSONDecoder().decode(WindowPlacementRequest.self, from: data),
        "Expected null \(key) to be rejected."
      )
    }
  }

  func testUsesStableCodableKeys() throws {
    let object = try encodedObject(WindowPlacementRequest(placement: .leftHalf))

    let placement = try XCTUnwrap(object["placement"] as? [String: Any])
    let screen = try XCTUnwrap(object["screen"] as? [String: Any])

    XCTAssertEqual(Set(object.keys), ["placement", "screen", "area", "inset"])
    XCTAssertEqual(placement["kind"] as? String, "left-half")
    XCTAssertEqual(screen["kind"] as? String, "containing-window")
    XCTAssertEqual(object["area"] as? String, "visible")
    XCTAssertEqual(object["inset"] as? Double, 0)
  }

  func testEncodesStableSimplePlacementKinds() throws {
    let cases: [(WindowPlacement, String)] = [
      (.fill, "fill"),
      (.leftHalf, "left-half"),
      (.rightHalf, "right-half"),
      (.topHalf, "top-half"),
      (.bottomHalf, "bottom-half"),
      (.topLeftQuarter, "top-left-quarter"),
      (.topRightQuarter, "top-right-quarter"),
      (.bottomLeftQuarter, "bottom-left-quarter"),
      (.bottomRightQuarter, "bottom-right-quarter"),
      (.leftThird, "left-third"),
      (.centerThird, "center-third"),
      (.rightThird, "right-third"),
      (.topThird, "top-third"),
      (.middleThird, "middle-third"),
      (.bottomThird, "bottom-third"),
      (.leftTwoThirds, "left-two-thirds"),
      (.rightTwoThirds, "right-two-thirds"),
      (.topTwoThirds, "top-two-thirds"),
      (.bottomTwoThirds, "bottom-two-thirds"),
    ]

    for (placement, expectedKind) in cases {
      let object = try encodedObject(WindowPlacementRequest(placement: placement))
      let payload = try XCTUnwrap(object["placement"] as? [String: Any])

      XCTAssertEqual(Set(payload.keys), ["kind"])
      XCTAssertEqual(payload["kind"] as? String, expectedKind)
    }
  }

  func testDecodesStableSimplePlacementKinds() throws {
    let cases: [(String, WindowPlacement)] = [
      ("fill", .fill),
      ("left-half", .leftHalf),
      ("right-half", .rightHalf),
      ("top-half", .topHalf),
      ("bottom-half", .bottomHalf),
      ("top-left-quarter", .topLeftQuarter),
      ("top-right-quarter", .topRightQuarter),
      ("bottom-left-quarter", .bottomLeftQuarter),
      ("bottom-right-quarter", .bottomRightQuarter),
      ("left-third", .leftThird),
      ("center-third", .centerThird),
      ("right-third", .rightThird),
      ("top-third", .topThird),
      ("middle-third", .middleThird),
      ("bottom-third", .bottomThird),
      ("left-two-thirds", .leftTwoThirds),
      ("right-two-thirds", .rightTwoThirds),
      ("top-two-thirds", .topTwoThirds),
      ("bottom-two-thirds", .bottomTwoThirds),
    ]

    for (kind, placement) in cases {
      XCTAssertEqual(
        try decodedRequest(placementPayload: ["kind": kind]),
        WindowPlacementRequest(placement: placement)
      )
    }
  }

  func testEncodesStableAssociatedPlacementPayloads() throws {
    let gridObject = try encodedObject(
      WindowPlacementRequest(
        placement: .grid(
          columns: 2,
          rows: 3,
          column: 1,
          row: 2,
          columnSpan: 1,
          rowSpan: 1
        )
      )
    )
    let grid = try XCTUnwrap(gridObject["placement"] as? [String: Any])

    XCTAssertEqual(
      Set(grid.keys),
      ["kind", "columns", "rows", "column", "row", "columnSpan", "rowSpan"]
    )
    XCTAssertEqual(grid["kind"] as? String, "grid")
    XCTAssertEqual(grid["columns"] as? Int, 2)
    XCTAssertEqual(grid["rows"] as? Int, 3)
    XCTAssertEqual(grid["column"] as? Int, 1)
    XCTAssertEqual(grid["row"] as? Int, 2)
    XCTAssertEqual(grid["columnSpan"] as? Int, 1)
    XCTAssertEqual(grid["rowSpan"] as? Int, 1)

    let centeredObject = try encodedObject(
      WindowPlacementRequest(placement: .centered(widthRatio: 0.7, heightRatio: 0.5))
    )
    let centered = try XCTUnwrap(centeredObject["placement"] as? [String: Any])

    XCTAssertEqual(Set(centered.keys), ["kind", "widthRatio", "heightRatio"])
    XCTAssertEqual(centered["kind"] as? String, "centered")
    XCTAssertEqual(centered["widthRatio"] as? Double, 0.7)
    XCTAssertEqual(centered["heightRatio"] as? Double, 0.5)
  }

  func testDecodesStableAssociatedPlacementPayloads() throws {
    XCTAssertEqual(
      try decodedRequest(
        placementPayload: [
          "kind": "grid",
          "columns": 2,
          "rows": 3,
          "column": 1,
          "row": 2,
          "columnSpan": 1,
          "rowSpan": 1,
        ]
      ),
      WindowPlacementRequest(
        placement: .grid(
          columns: 2,
          rows: 3,
          column: 1,
          row: 2,
          columnSpan: 1,
          rowSpan: 1
        )
      )
    )

    XCTAssertEqual(
      try decodedRequest(
        placementPayload: [
          "kind": "centered",
          "widthRatio": 0.7,
          "heightRatio": 0.5,
        ]
      ),
      WindowPlacementRequest(placement: .centered(widthRatio: 0.7, heightRatio: 0.5))
    )
  }

  func testEncodesStableScreenPayloads() throws {
    let cases: [(WindowScreenTarget, String, Set<String>)] = [
      (.main, "main", ["kind"]),
      (.containingWindow, "containing-window", ["kind"]),
      (.orderedIndex(2), "ordered-index", ["kind", "orderedIndex"]),
      (.displayIdentifier(7), "display-identifier", ["kind", "displayIdentifier"]),
      (.point(.init(x: 10, y: 20)), "point", ["kind", "x", "y"]),
    ]

    for (screen, expectedKind, expectedKeys) in cases {
      let object = try encodedObject(WindowPlacementRequest(placement: .leftHalf, screen: screen))
      let payload = try XCTUnwrap(object["screen"] as? [String: Any])

      XCTAssertEqual(Set(payload.keys), expectedKeys)
      XCTAssertEqual(payload["kind"] as? String, expectedKind)
    }
  }

  func testDecodesStableScreenPayloads() throws {
    let cases: [([String: Any], WindowScreenTarget)] = [
      (["kind": "main"], .main),
      (["kind": "containing-window"], .containingWindow),
      (["kind": "ordered-index", "orderedIndex": 2], .orderedIndex(2)),
      (["kind": "display-identifier", "displayIdentifier": 7], .displayIdentifier(7)),
      (["kind": "point", "x": 10, "y": 20], .point(.init(x: 10, y: 20))),
    ]

    for (payload, screen) in cases {
      XCTAssertEqual(
        try decodedRequest(screenPayload: payload),
        WindowPlacementRequest(placement: .leftHalf, screen: screen)
      )
    }
  }

  func testEncodesStableScreenAssociatedValues() throws {
    let orderedIndex = try screenPayload(for: .orderedIndex(2))
    XCTAssertEqual(orderedIndex["orderedIndex"] as? Int, 2)

    let displayIdentifier = try screenPayload(for: .displayIdentifier(7))
    XCTAssertEqual(displayIdentifier["displayIdentifier"] as? Int, 7)

    let point = try screenPayload(for: .point(.init(x: 10, y: 20)))
    XCTAssertEqual((point["x"] as? NSNumber)?.doubleValue, 10)
    XCTAssertEqual((point["y"] as? NSNumber)?.doubleValue, 20)
  }

  func testEncodesStableAreaValues() throws {
    let visible = try encodedObject(WindowPlacementRequest(placement: .leftHalf, area: .visible))
    XCTAssertEqual(visible["area"] as? String, "visible")

    let full = try encodedObject(WindowPlacementRequest(placement: .leftHalf, area: .full))
    XCTAssertEqual(full["area"] as? String, "full")
  }

  func testDecodesStableAreaValues() throws {
    XCTAssertEqual(
      try decodedRequest(area: "visible"),
      WindowPlacementRequest(placement: .leftHalf, area: .visible)
    )
    XCTAssertEqual(
      try decodedRequest(area: "full"),
      WindowPlacementRequest(placement: .leftHalf, area: .full)
    )
  }

  func testDecodesStableCodablePayload() throws {
    let data = Data(
      """
      {
        "placement": {
          "kind": "grid",
          "columns": 2,
          "rows": 3,
          "column": 1,
          "row": 2,
          "columnSpan": 1,
          "rowSpan": 1
        },
        "screen": {
          "kind": "point",
          "x": 10,
          "y": 20
        },
        "area": "full",
        "inset": 6
      }
      """.utf8
    )

    XCTAssertEqual(
      try JSONDecoder().decode(WindowPlacementRequest.self, from: data),
      WindowPlacementRequest(
        placement: .grid(
          columns: 2,
          rows: 3,
          column: 1,
          row: 2,
          columnSpan: 1,
          rowSpan: 1
        ),
        screen: .point(.init(x: 10, y: 20)),
        area: .full,
        inset: 6
      )
    )
  }

  func testDecodingRequiresPlacement() {
    let data = Data(
      """
      {
        "screen": {
          "kind": "containing-window"
        },
        "area": "visible",
        "inset": 0
      }
      """.utf8
    )

    XCTAssertThrowsError(try JSONDecoder().decode(WindowPlacementRequest.self, from: data))
  }

  private func encodedObject(_ request: WindowPlacementRequest) throws -> [String: Any] {
    let data = try JSONEncoder().encode(request)
    return try XCTUnwrap(JSONSerialization.jsonObject(with: data) as? [String: Any])
  }

  private func screenPayload(for screen: WindowScreenTarget) throws -> [String: Any] {
    let object = try encodedObject(WindowPlacementRequest(placement: .leftHalf, screen: screen))
    return try XCTUnwrap(object["screen"] as? [String: Any])
  }

  private func decodedRequest(
    placementPayload: [String: Any] = ["kind": "left-half"],
    screenPayload: [String: Any] = ["kind": "containing-window"],
    area: String = "visible",
    inset: Double = 0
  ) throws -> WindowPlacementRequest {
    let data = try JSONSerialization.data(
      withJSONObject: [
        "placement": placementPayload,
        "screen": screenPayload,
        "area": area,
        "inset": inset,
      ]
    )
    return try JSONDecoder().decode(WindowPlacementRequest.self, from: data)
  }
}

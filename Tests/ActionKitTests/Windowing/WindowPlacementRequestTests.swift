import CoreGraphics
import XCTest

import ActionKit

final class WindowPlacementRequestTests: XCTestCase {
  func testNormalizesPlacementGeometryToExecutableRanges() {
    XCTAssertEqual(
      WindowPlacementRequest(
        placement: .grid(
          columns: 0,
          rows: -2,
          column: 4,
          row: -1,
          columnSpan: 0,
          rowSpan: 9
        )
      ).placement,
      .grid(columns: 1, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1)
    )
    XCTAssertEqual(
      WindowPlacementRequest(
        placement: .centered(widthRatio: .infinity, heightRatio: .nan)
      ).placement,
      .centered(widthRatio: 1, heightRatio: 0)
    )
  }

  func testNormalizesInvalidScreenSelectors() {
    XCTAssertEqual(
      WindowPlacementRequest(
        placement: .fill,
        screen: .point(.init(x: .nan, y: -.infinity))
      ).screen,
      .point(.zero)
    )
    XCTAssertEqual(
      WindowPlacementRequest(placement: .fill, screen: .orderedIndex(-1)).screen,
      .orderedIndex(0)
    )
  }

  func testStandaloneWindowValuesCanonicalizeAtCodableBoundaries() throws {
    let placementData = try JSONEncoder().encode(
      ActionWindowPlacement.centered(widthRatio: .infinity, heightRatio: -.infinity)
    )
    XCTAssertEqual(
      try JSONDecoder().decode(ActionWindowPlacement.self, from: placementData),
      .centered(widthRatio: 1, heightRatio: 0)
    )

    let screenData = try JSONEncoder().encode(
      ActionWindowScreenTarget.point(
        CGPoint(x: CGFloat.nan, y: CGFloat.infinity)
      )
    )
    XCTAssertEqual(
      try JSONDecoder().decode(ActionWindowScreenTarget.self, from: screenData),
      .point(.zero)
    )

    let invalidGridData =
      #"{"kind":"grid","columns":0,"rows":-1,"column":8,"row":-2,"columnSpan":0,"rowSpan":9}"#.data(
        using: .utf8
      )!
    XCTAssertEqual(
      try JSONDecoder().decode(ActionWindowPlacement.self, from: invalidGridData),
      .grid(columns: 1, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1)
    )
  }

  func testUsesFocusedWindowDefaults() {
    let request = WindowPlacementRequest(placement: .fill)

    XCTAssertEqual(request.screen, .containingWindow)
    XCTAssertEqual(request.area, .visible)
    XCTAssertEqual(request.inset, 0)
  }

  func testNormalizesInvalidInsets() {
    XCTAssertEqual(WindowPlacementRequest(placement: .fill, inset: -1).inset, 0)
    XCTAssertEqual(WindowPlacementRequest(placement: .fill, inset: .infinity).inset, 0)
    XCTAssertEqual(WindowPlacementRequest(placement: .fill, inset: .nan).inset, 0)
  }

  func testRoundTripsCodable() throws {
    let requests = [
      WindowPlacementRequest(placement: .fill),
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
        placement: .grid(columns: 3, rows: 1, column: 1, row: 0, columnSpan: 2, rowSpan: 1),
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

  func testPublicWindowValueTypesRoundTripCodable() throws {
    let placements: [ActionWindowPlacement] = [
      .fill,
      .grid(columns: 2, rows: 3, column: 1, row: 2, columnSpan: 1, rowSpan: 1),
      .centered(widthRatio: 0.7, heightRatio: 0.5),
    ]
    let screens: [ActionWindowScreenTarget] = [
      .main,
      .containingWindow,
      .orderedIndex(2),
      .displayIdentifier(7),
      .point(.init(x: 10, y: 20)),
    ]
    let areas: [ActionWindowScreenArea] = [.visible, .full]

    let encoder = JSONEncoder()
    let decoder = JSONDecoder()

    for placement in placements {
      XCTAssertEqual(
        try decoder.decode(ActionWindowPlacement.self, from: encoder.encode(placement)),
        placement
      )
    }
    for screen in screens {
      XCTAssertEqual(
        try decoder.decode(ActionWindowScreenTarget.self, from: encoder.encode(screen)),
        screen
      )
    }
    for area in areas {
      XCTAssertEqual(
        try decoder.decode(ActionWindowScreenArea.self, from: encoder.encode(area)),
        area
      )
    }
  }

  func testDecodingNormalizesInvalidInsets() throws {
    let encoded = try JSONEncoder().encode(WindowPlacementRequest(placement: .fill))
    var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    payload["inset"] = -1
    let data = try JSONSerialization.data(withJSONObject: payload)

    let request = try JSONDecoder().decode(WindowPlacementRequest.self, from: data)

    XCTAssertEqual(request.inset, 0)
  }

  func testDecodingUsesFocusedWindowDefaultsWhenOptionalFieldsAreOmitted() throws {
    let encoded = try JSONEncoder().encode(WindowPlacementRequest(placement: .fill))
    var payload = try XCTUnwrap(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
    payload.removeValue(forKey: "screen")
    payload.removeValue(forKey: "area")
    payload.removeValue(forKey: "inset")
    let data = try JSONSerialization.data(withJSONObject: payload)

    XCTAssertEqual(
      try JSONDecoder().decode(WindowPlacementRequest.self, from: data),
      WindowPlacementRequest(placement: .fill)
    )
  }

  func testDecodingRejectsNullFocusedWindowDefaults() throws {
    let encoded = try JSONEncoder().encode(WindowPlacementRequest(placement: .fill))

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

  func testDecodingRejectsUnknownTopLevelFields() {
    let data = Data(
      """
      {
        "placement": { "kind": "fill" },
        "screen": { "kind": "containing-window" },
        "area": "visible",
        "inset": 0,
        "metadata": {}
      }
      """.utf8
    )

    XCTAssertThrowsError(try JSONDecoder().decode(WindowPlacementRequest.self, from: data))
  }

  func testUsesCanonicalCodableKeys() throws {
    let object = try encodedObject(WindowPlacementRequest(placement: .fill))

    let placement = try XCTUnwrap(object["placement"] as? [String: Any])
    let screen = try XCTUnwrap(object["screen"] as? [String: Any])

    XCTAssertEqual(Set(object.keys), ["placement", "screen", "area", "inset"])
    XCTAssertEqual(placement["kind"] as? String, "fill")
    XCTAssertEqual(screen["kind"] as? String, "containing-window")
    XCTAssertEqual(object["area"] as? String, "visible")
    XCTAssertEqual(object["inset"] as? Double, 0)
  }

  func testEncodesCanonicalFillPlacementPayload() throws {
    let object = try encodedObject(WindowPlacementRequest(placement: .fill))
    let payload = try XCTUnwrap(object["placement"] as? [String: Any])

    XCTAssertEqual(Set(payload.keys), ["kind"])
    XCTAssertEqual(payload["kind"] as? String, "fill")
  }

  func testDecodesCanonicalFillPlacementPayload() throws {
    XCTAssertEqual(
      try decodedRequest(placementPayload: ["kind": "fill"]),
      WindowPlacementRequest(placement: .fill)
    )
  }

  func testEncodesCanonicalAssociatedPlacementPayloads() throws {
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

  func testDecodesCanonicalAssociatedPlacementPayloads() throws {
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

  func testDecodingRejectsPlacementAssociatedFieldsForWrongKind() {
    let payloads: [[String: Any]] = [
      [
        "kind": "fill",
        "columns": 2,
      ],
      [
        "kind": "grid",
        "columns": 2,
        "rows": 3,
        "column": 1,
        "row": 2,
        "columnSpan": 1,
        "rowSpan": 1,
        "widthRatio": 0.7,
      ],
      [
        "kind": "centered",
        "widthRatio": 0.7,
        "heightRatio": 0.5,
        "column": 1,
      ],
    ]

    for payload in payloads {
      XCTAssertThrowsError(try decodedRequest(placementPayload: payload))
    }
  }

  func testDecodingRejectsUnknownPlacementFields() {
    XCTAssertThrowsError(
      try decodedRequest(
        placementPayload: [
          "kind": "fill",
          "metadata": [:],
        ]
      )
    )
  }

  func testEncodesCanonicalScreenPayloads() throws {
    let cases: [(ActionWindowScreenTarget, String, Set<String>)] = [
      (.main, "main", ["kind"]),
      (.containingWindow, "containing-window", ["kind"]),
      (.orderedIndex(2), "ordered-index", ["kind", "orderedIndex"]),
      (.displayIdentifier(7), "display-identifier", ["kind", "displayIdentifier"]),
      (.point(.init(x: 10, y: 20)), "point", ["kind", "x", "y"]),
    ]

    for (screen, expectedKind, expectedKeys) in cases {
      let object = try encodedObject(WindowPlacementRequest(placement: .fill, screen: screen))
      let payload = try XCTUnwrap(object["screen"] as? [String: Any])

      XCTAssertEqual(Set(payload.keys), expectedKeys)
      XCTAssertEqual(payload["kind"] as? String, expectedKind)
    }
  }

  func testDecodesCanonicalScreenPayloads() throws {
    let cases: [([String: Any], ActionWindowScreenTarget)] = [
      (["kind": "main"], .main),
      (["kind": "containing-window"], .containingWindow),
      (["kind": "ordered-index", "orderedIndex": 2], .orderedIndex(2)),
      (["kind": "display-identifier", "displayIdentifier": 7], .displayIdentifier(7)),
      (["kind": "point", "x": 10, "y": 20], .point(.init(x: 10, y: 20))),
    ]

    for (payload, screen) in cases {
      XCTAssertEqual(
        try decodedRequest(screenPayload: payload),
        WindowPlacementRequest(placement: .fill, screen: screen)
      )
    }
  }

  func testDecodingRejectsScreenAssociatedFieldsForWrongKind() {
    let payloads: [[String: Any]] = [
      [
        "kind": "main",
        "x": 10,
      ],
      [
        "kind": "containing-window",
        "orderedIndex": 2,
      ],
      [
        "kind": "point",
        "x": 10,
        "y": 20,
        "displayIdentifier": 7,
      ],
      [
        "kind": "ordered-index",
        "orderedIndex": 2,
        "x": 10,
      ],
    ]

    for payload in payloads {
      XCTAssertThrowsError(try decodedRequest(screenPayload: payload))
    }
  }

  func testDecodingRejectsUnknownScreenFields() {
    XCTAssertThrowsError(
      try decodedRequest(
        screenPayload: [
          "kind": "containing-window",
          "metadata": [:],
        ]
      )
    )
  }

  func testEncodesCanonicalScreenAssociatedValues() throws {
    let orderedIndex = try screenPayload(for: .orderedIndex(2))
    XCTAssertEqual(orderedIndex["orderedIndex"] as? Int, 2)

    let displayIdentifier = try screenPayload(for: .displayIdentifier(7))
    XCTAssertEqual(displayIdentifier["displayIdentifier"] as? Int, 7)

    let point = try screenPayload(for: .point(.init(x: 10, y: 20)))
    XCTAssertEqual((point["x"] as? NSNumber)?.doubleValue, 10)
    XCTAssertEqual((point["y"] as? NSNumber)?.doubleValue, 20)
  }

  func testEncodesCanonicalAreaValues() throws {
    let visible = try encodedObject(WindowPlacementRequest(placement: .fill, area: .visible))
    XCTAssertEqual(visible["area"] as? String, "visible")

    let full = try encodedObject(WindowPlacementRequest(placement: .fill, area: .full))
    XCTAssertEqual(full["area"] as? String, "full")
  }

  func testDecodesCanonicalAreaValues() throws {
    XCTAssertEqual(
      try decodedRequest(area: "visible"),
      WindowPlacementRequest(placement: .fill, area: .visible)
    )
    XCTAssertEqual(
      try decodedRequest(area: "full"),
      WindowPlacementRequest(placement: .fill, area: .full)
    )
  }

  func testDecodesCanonicalCodablePayload() throws {
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

  private func screenPayload(for screen: ActionWindowScreenTarget) throws -> [String: Any] {
    let object = try encodedObject(
      WindowPlacementRequest(
        placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1),
        screen: screen))
    return try XCTUnwrap(object["screen"] as? [String: Any])
  }

  private func decodedRequest(
    placementPayload: [String: Any] = ["kind": "fill"],
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

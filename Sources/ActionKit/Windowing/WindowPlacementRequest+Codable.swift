import CoreGraphics
import WindowKit

extension WindowPlacementRequest: Codable {
  private enum CodingKeys: String, CodingKey {
    case placement
    case screen
    case area
    case inset
  }

  private enum PayloadCodingKeys: String, CodingKey {
    case kind
    case columns
    case rows
    case column
    case row
    case columnSpan
    case rowSpan
    case widthRatio
    case heightRatio
    case x
    case y
    case displayIdentifier
    case orderedIndex
  }

  private enum PlacementPayloadKind: String, Codable {
    case fill
    case leftHalf = "left-half"
    case rightHalf = "right-half"
    case topHalf = "top-half"
    case bottomHalf = "bottom-half"
    case topLeftQuarter = "top-left-quarter"
    case topRightQuarter = "top-right-quarter"
    case bottomLeftQuarter = "bottom-left-quarter"
    case bottomRightQuarter = "bottom-right-quarter"
    case leftThird = "left-third"
    case centerThird = "center-third"
    case rightThird = "right-third"
    case topThird = "top-third"
    case middleThird = "middle-third"
    case bottomThird = "bottom-third"
    case leftTwoThirds = "left-two-thirds"
    case rightTwoThirds = "right-two-thirds"
    case topTwoThirds = "top-two-thirds"
    case bottomTwoThirds = "bottom-two-thirds"
    case grid
    case centered
  }

  private enum ScreenPayloadKind: String, Codable {
    case main
    case containingWindow = "containing-window"
    case point
    case displayIdentifier = "display-identifier"
    case orderedIndex = "ordered-index"
  }

  private enum ScreenAreaPayload: String, Codable {
    case full
    case visible
  }

  private struct PlacementPayload: Codable {
    var placement: WindowPlacement

    init(_ placement: WindowPlacement) {
      self.placement = placement
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: PayloadCodingKeys.self)

      switch try container.decode(PlacementPayloadKind.self, forKey: .kind) {
      case .fill:
        placement = .fill
      case .leftHalf:
        placement = .leftHalf
      case .rightHalf:
        placement = .rightHalf
      case .topHalf:
        placement = .topHalf
      case .bottomHalf:
        placement = .bottomHalf
      case .topLeftQuarter:
        placement = .topLeftQuarter
      case .topRightQuarter:
        placement = .topRightQuarter
      case .bottomLeftQuarter:
        placement = .bottomLeftQuarter
      case .bottomRightQuarter:
        placement = .bottomRightQuarter
      case .leftThird:
        placement = .leftThird
      case .centerThird:
        placement = .centerThird
      case .rightThird:
        placement = .rightThird
      case .topThird:
        placement = .topThird
      case .middleThird:
        placement = .middleThird
      case .bottomThird:
        placement = .bottomThird
      case .leftTwoThirds:
        placement = .leftTwoThirds
      case .rightTwoThirds:
        placement = .rightTwoThirds
      case .topTwoThirds:
        placement = .topTwoThirds
      case .bottomTwoThirds:
        placement = .bottomTwoThirds
      case .grid:
        placement = .grid(
          columns: try container.decode(Int.self, forKey: .columns),
          rows: try container.decode(Int.self, forKey: .rows),
          column: try container.decode(Int.self, forKey: .column),
          row: try container.decode(Int.self, forKey: .row),
          columnSpan: try container.decode(Int.self, forKey: .columnSpan),
          rowSpan: try container.decode(Int.self, forKey: .rowSpan)
        )
      case .centered:
        placement = .centered(
          widthRatio: try container.decode(CGFloat.self, forKey: .widthRatio),
          heightRatio: try container.decode(CGFloat.self, forKey: .heightRatio)
        )
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: PayloadCodingKeys.self)

      switch placement {
      case .fill:
        try container.encode(PlacementPayloadKind.fill, forKey: .kind)
      case .leftHalf:
        try container.encode(PlacementPayloadKind.leftHalf, forKey: .kind)
      case .rightHalf:
        try container.encode(PlacementPayloadKind.rightHalf, forKey: .kind)
      case .topHalf:
        try container.encode(PlacementPayloadKind.topHalf, forKey: .kind)
      case .bottomHalf:
        try container.encode(PlacementPayloadKind.bottomHalf, forKey: .kind)
      case .topLeftQuarter:
        try container.encode(PlacementPayloadKind.topLeftQuarter, forKey: .kind)
      case .topRightQuarter:
        try container.encode(PlacementPayloadKind.topRightQuarter, forKey: .kind)
      case .bottomLeftQuarter:
        try container.encode(PlacementPayloadKind.bottomLeftQuarter, forKey: .kind)
      case .bottomRightQuarter:
        try container.encode(PlacementPayloadKind.bottomRightQuarter, forKey: .kind)
      case .leftThird:
        try container.encode(PlacementPayloadKind.leftThird, forKey: .kind)
      case .centerThird:
        try container.encode(PlacementPayloadKind.centerThird, forKey: .kind)
      case .rightThird:
        try container.encode(PlacementPayloadKind.rightThird, forKey: .kind)
      case .topThird:
        try container.encode(PlacementPayloadKind.topThird, forKey: .kind)
      case .middleThird:
        try container.encode(PlacementPayloadKind.middleThird, forKey: .kind)
      case .bottomThird:
        try container.encode(PlacementPayloadKind.bottomThird, forKey: .kind)
      case .leftTwoThirds:
        try container.encode(PlacementPayloadKind.leftTwoThirds, forKey: .kind)
      case .rightTwoThirds:
        try container.encode(PlacementPayloadKind.rightTwoThirds, forKey: .kind)
      case .topTwoThirds:
        try container.encode(PlacementPayloadKind.topTwoThirds, forKey: .kind)
      case .bottomTwoThirds:
        try container.encode(PlacementPayloadKind.bottomTwoThirds, forKey: .kind)
      case .grid(
        let columns,
        let rows,
        let column,
        let row,
        let columnSpan,
        let rowSpan
      ):
        try container.encode(PlacementPayloadKind.grid, forKey: .kind)
        try container.encode(columns, forKey: .columns)
        try container.encode(rows, forKey: .rows)
        try container.encode(column, forKey: .column)
        try container.encode(row, forKey: .row)
        try container.encode(columnSpan, forKey: .columnSpan)
        try container.encode(rowSpan, forKey: .rowSpan)
      case .centered(let widthRatio, let heightRatio):
        try container.encode(PlacementPayloadKind.centered, forKey: .kind)
        try container.encode(widthRatio, forKey: .widthRatio)
        try container.encode(heightRatio, forKey: .heightRatio)
      }
    }
  }

  private struct ScreenPayload: Codable {
    var screen: WindowScreenTarget

    init(_ screen: WindowScreenTarget) {
      self.screen = screen
    }

    init(from decoder: Decoder) throws {
      let container = try decoder.container(keyedBy: PayloadCodingKeys.self)

      switch try container.decode(ScreenPayloadKind.self, forKey: .kind) {
      case .main:
        screen = .main
      case .containingWindow:
        screen = .containingWindow
      case .point:
        screen = .point(
          CGPoint(
            x: try container.decode(CGFloat.self, forKey: .x),
            y: try container.decode(CGFloat.self, forKey: .y)
          )
        )
      case .displayIdentifier:
        screen = .displayIdentifier(
          try container.decode(CGDirectDisplayID.self, forKey: .displayIdentifier)
        )
      case .orderedIndex:
        screen = .orderedIndex(try container.decode(Int.self, forKey: .orderedIndex))
      }
    }

    func encode(to encoder: Encoder) throws {
      var container = encoder.container(keyedBy: PayloadCodingKeys.self)

      switch screen {
      case .main:
        try container.encode(ScreenPayloadKind.main, forKey: .kind)
      case .containingWindow:
        try container.encode(ScreenPayloadKind.containingWindow, forKey: .kind)
      case .point(let point):
        try container.encode(ScreenPayloadKind.point, forKey: .kind)
        try container.encode(point.x, forKey: .x)
        try container.encode(point.y, forKey: .y)
      case .displayIdentifier(let displayIdentifier):
        try container.encode(ScreenPayloadKind.displayIdentifier, forKey: .kind)
        try container.encode(displayIdentifier, forKey: .displayIdentifier)
      case .orderedIndex(let orderedIndex):
        try container.encode(ScreenPayloadKind.orderedIndex, forKey: .kind)
        try container.encode(orderedIndex, forKey: .orderedIndex)
      }
    }
  }

  private static func area(_ payload: ScreenAreaPayload) -> WindowScreenArea {
    switch payload {
    case .full: .full
    case .visible: .visible
    }
  }

  private static func areaPayload(_ area: WindowScreenArea) -> ScreenAreaPayload {
    switch area {
    case .full: .full
    case .visible: .visible
    }
  }

  /// Decodes a placement request and applies the same inset normalization as direct creation.
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    self.init(
      placement: try container.decode(PlacementPayload.self, forKey: .placement).placement,
      screen: try container.contains(.screen)
        ? container.decode(ScreenPayload.self, forKey: .screen).screen
        : .containingWindow,
      area: try container.contains(.area)
        ? Self.area(container.decode(ScreenAreaPayload.self, forKey: .area))
        : .visible,
      inset: try container.contains(.inset)
        ? container.decode(CGFloat.self, forKey: .inset)
        : 0
    )
  }

  /// Encodes a placement request using stable public field names.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(PlacementPayload(placement), forKey: .placement)
    try container.encode(ScreenPayload(screen), forKey: .screen)
    try container.encode(Self.areaPayload(area), forKey: .area)
    try container.encode(inset, forKey: .inset)
  }
}

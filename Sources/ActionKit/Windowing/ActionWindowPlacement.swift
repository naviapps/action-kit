import CoreGraphics

/// ActionKit-owned placement description for focused-window actions.
public enum ActionWindowPlacement: Equatable, Hashable, Sendable {
  case fill
  case grid(columns: Int, rows: Int, column: Int, row: Int, columnSpan: Int, rowSpan: Int)
  case centered(widthRatio: CGFloat, heightRatio: CGFloat)
}

extension ActionWindowPlacement {
  var normalized: Self {
    switch self {
    case .fill:
      .fill
    case let .grid(columns, rows, column, row, columnSpan, rowSpan):
      Self.normalizedGrid(
        columns: columns,
        rows: rows,
        column: column,
        row: row,
        columnSpan: columnSpan,
        rowSpan: rowSpan
      )
    case let .centered(widthRatio, heightRatio):
      .centered(
        widthRatio: Self.normalizedRatio(widthRatio),
        heightRatio: Self.normalizedRatio(heightRatio)
      )
    }
  }

  private static func normalizedGrid(
    columns: Int,
    rows: Int,
    column: Int,
    row: Int,
    columnSpan: Int,
    rowSpan: Int
  ) -> Self {
    let columns = max(1, columns)
    let rows = max(1, rows)
    let column = min(max(0, column), columns - 1)
    let row = min(max(0, row), rows - 1)
    return .grid(
      columns: columns,
      rows: rows,
      column: column,
      row: row,
      columnSpan: min(max(1, columnSpan), columns - column),
      rowSpan: min(max(1, rowSpan), rows - row)
    )
  }

  private static func normalizedRatio(_ ratio: CGFloat) -> CGFloat {
    guard ratio.isFinite else {
      return ratio > 1 ? 1 : 0
    }
    return min(max(0, ratio), 1)
  }
}

extension ActionWindowPlacement: Codable {
  private enum CodingKeys: String, CodingKey {
    case kind
    case columns
    case rows
    case column
    case row
    case columnSpan
    case rowSpan
    case widthRatio
    case heightRatio
  }

  private enum Kind: String, Codable {
    case fill
    case grid
    case centered
  }

  /// Decodes a window placement from ActionKit's canonical payload shape.
  public init(from decoder: Decoder) throws {
    try decoder.rejectUnknownKeys(
      allowed: [
        CodingKeys.kind,
        .columns,
        .rows,
        .column,
        .row,
        .columnSpan,
        .rowSpan,
        .widthRatio,
        .heightRatio,
      ],
      debugName: "ActionWindowPlacement"
    )
    let container = try decoder.container(keyedBy: CodingKeys.self)

    let decoded: Self
    switch try container.decode(Kind.self, forKey: .kind) {
    case .fill:
      try Self.rejectAssociatedPlacementFields(in: container)
      decoded = .fill
    case .grid:
      try Self.rejectFields([.widthRatio, .heightRatio], in: container)
      decoded = .grid(
        columns: try container.decode(Int.self, forKey: .columns),
        rows: try container.decode(Int.self, forKey: .rows),
        column: try container.decode(Int.self, forKey: .column),
        row: try container.decode(Int.self, forKey: .row),
        columnSpan: try container.decode(Int.self, forKey: .columnSpan),
        rowSpan: try container.decode(Int.self, forKey: .rowSpan)
      )
    case .centered:
      try Self.rejectFields(
        [.columns, .rows, .column, .row, .columnSpan, .rowSpan],
        in: container
      )
      decoded = .centered(
        widthRatio: try container.decode(CGFloat.self, forKey: .widthRatio),
        heightRatio: try container.decode(CGFloat.self, forKey: .heightRatio)
      )
    }
    self = decoded.normalized
  }

  /// Encodes the window placement using ActionKit's canonical payload shape.
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)

    switch normalized {
    case .fill:
      try container.encode(Kind.fill, forKey: .kind)
    case let .grid(columns, rows, column, row, columnSpan, rowSpan):
      try container.encode(Kind.grid, forKey: .kind)
      try container.encode(columns, forKey: .columns)
      try container.encode(rows, forKey: .rows)
      try container.encode(column, forKey: .column)
      try container.encode(row, forKey: .row)
      try container.encode(columnSpan, forKey: .columnSpan)
      try container.encode(rowSpan, forKey: .rowSpan)
    case let .centered(widthRatio, heightRatio):
      try container.encode(Kind.centered, forKey: .kind)
      try container.encode(widthRatio, forKey: .widthRatio)
      try container.encode(heightRatio, forKey: .heightRatio)
    }
  }

  private static func rejectAssociatedPlacementFields(
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    try rejectFields(
      [.columns, .rows, .column, .row, .columnSpan, .rowSpan, .widthRatio, .heightRatio],
      in: container
    )
  }

  private static func rejectFields(
    _ keys: [CodingKeys],
    in container: KeyedDecodingContainer<CodingKeys>
  ) throws {
    for key in keys where container.contains(key) {
      throw DecodingError.dataCorruptedError(
        forKey: key,
        in: container,
        debugDescription: "\(key.stringValue) is not valid for this window placement kind."
      )
    }
  }
}

import ActionKit
import WindowKit

package enum ActionWindowMapper {
  package static func placement(_ placement: ActionWindowPlacement) -> WindowPlacement {
    switch placement {
    case .fill:
      .fill
    case let .grid(columns, rows, column, row, columnSpan, rowSpan):
      .grid(
        columns: columns,
        rows: rows,
        column: column,
        row: row,
        columnSpan: columnSpan,
        rowSpan: rowSpan
      )
    case let .centered(widthRatio, heightRatio):
      .centered(widthRatio: widthRatio, heightRatio: heightRatio)
    }
  }

  package static func screenTarget(_ screen: ActionWindowScreenTarget) -> WindowScreenTarget {
    switch screen {
    case .main:
      .main
    case .containingWindow:
      .containingWindow
    case let .point(point):
      .point(point)
    case let .displayIdentifier(displayIdentifier):
      .displayIdentifier(displayIdentifier)
    case let .orderedIndex(index):
      .orderedIndex(index)
    }
  }

  package static func screenArea(_ area: ActionWindowScreenArea) -> WindowScreenArea {
    switch area {
    case .full:
      .full
    case .visible:
      .visible
    }
  }

  package static func screenCycleDirection(
    _ direction: ActionWindowScreenCycleDirection
  ) -> WindowScreenCycleDirection {
    switch direction {
    case .next:
      .next
    case .previous:
      .previous
    }
  }
}

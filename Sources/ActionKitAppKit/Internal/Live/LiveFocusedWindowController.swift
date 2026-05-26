import ActionKit
import WindowKitAppKit

struct LiveFocusedWindowController: FocusedWindowControlling {
  @MainActor
  func place(_ request: WindowPlacementRequest) throws {
    let placer = WindowPlacer()
    try placer.place(
      request.placement,
      for: .focused,
      screen: request.screen,
      area: request.area,
      inset: request.inset,
      allowsScreenFallback: false
    )
  }

  @MainActor
  func moveToAdjacentScreen(_ request: WindowMoveRequest) throws {
    let placer = WindowPlacer()
    try placer.moveToAdjacentScreen(
      request.direction,
      for: .focused,
      preservingRelativePosition: request.preservesRelativePosition,
      allowsScreenFallback: false
    )
  }
}

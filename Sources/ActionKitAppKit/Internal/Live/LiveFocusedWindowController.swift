import ActionKit
import WindowKit
import WindowKitAppKit

struct LiveFocusedWindowController: FocusedWindowControlling {
  @MainActor
  func place(_ request: WindowPlacementRequest) throws(FocusedWindowControlError) {
    let placer = WindowPlacer()
    do {
      try placer.place(
        ActionWindowMapper.placement(request.placement),
        for: .focused,
        screen: ActionWindowMapper.screenTarget(request.screen),
        area: ActionWindowMapper.screenArea(request.area),
        inset: request.inset,
        screenFallback: .none
      )
    } catch let error as WindowPlacerError {
      throw FocusedWindowControlError(error)
    } catch let error as WindowAccessibilityError {
      throw FocusedWindowControlError(error)
    } catch {
      throw .unexpected(String(describing: error))
    }
  }

  @MainActor
  func moveToAdjacentScreen(_ request: WindowMoveRequest) throws(FocusedWindowControlError) {
    let placer = WindowPlacer()
    do {
      try placer.moveToAdjacentScreen(
        ActionWindowMapper.screenCycleDirection(request.direction),
        for: .focused,
        preservingRelativePosition: request.preservesRelativePosition,
        screenFallback: .none
      )
    } catch let error as WindowPlacerError {
      throw FocusedWindowControlError(error)
    } catch let error as WindowAccessibilityError {
      throw FocusedWindowControlError(error)
    } catch {
      throw .unexpected(String(describing: error))
    }
  }
}

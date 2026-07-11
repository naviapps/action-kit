extension ActionPreflight {
  static func windowingPlan(for action: Action) -> ActionPlan? {
    switch action {
    case .windowPlacement(let request):
      windowPlacementPlan(request)
    case .windowMove(let request):
      windowMovePlan(request)
    default:
      nil
    }
  }

  private static func windowPlacementPlan(_ request: WindowPlacementRequest) -> ActionPlan {
    singleStepPlan(method: .windowing(.placeFocusedWindow(request)))
  }

  private static func windowMovePlan(_ request: WindowMoveRequest) -> ActionPlan {
    singleStepPlan(method: .windowing(.moveFocusedWindow(request)))
  }
}

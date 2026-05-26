extension ActionPreflight {
  static func windowingPlan(for action: Action) -> ActionPlan? {
    switch action {
    case .windowMaximize:
      windowPlacementPlan(.init(placement: .fill))
    case .windowLeftHalf:
      windowPlacementPlan(.init(placement: .leftHalf))
    case .windowRightHalf:
      windowPlacementPlan(.init(placement: .rightHalf))
    case .windowTopHalf:
      windowPlacementPlan(.init(placement: .topHalf))
    case .windowBottomHalf:
      windowPlacementPlan(.init(placement: .bottomHalf))
    case .windowCenter:
      windowPlacementPlan(.init(placement: .centered(widthRatio: 0.85, heightRatio: 0.85)))
    case .windowMoveToNextScreen:
      windowMovePlan(.init(direction: .next))
    case .windowMoveToPreviousScreen:
      windowMovePlan(.init(direction: .previous))
    case .windowPlacement(let request):
      windowPlacementPlan(request)
    case .windowMove(let request):
      windowMovePlan(request)
    default:
      nil
    }
  }

  private static func windowPlacementPlan(_ request: WindowPlacementRequest) -> ActionPlan {
    singleStepPlan(
      method: .windowing(.placeFocusedWindow(request)),
      requiredPermissions: [.accessibility]
    )
  }

  private static func windowMovePlan(_ request: WindowMoveRequest) -> ActionPlan {
    singleStepPlan(
      method: .windowing(.moveFocusedWindow(request)),
      requiredPermissions: [.accessibility]
    )
  }
}

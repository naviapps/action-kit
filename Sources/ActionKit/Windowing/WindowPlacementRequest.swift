import CoreGraphics

/// A request to place the focused window.
public struct WindowPlacementRequest: Sendable, Equatable, Hashable {
  /// The target placement geometry.
  public let placement: ActionWindowPlacement
  /// The screen selection rule.
  public let screen: ActionWindowScreenTarget
  /// The screen area used for placement.
  public let area: ActionWindowScreenArea
  /// The inset applied to the placement frame.
  public let inset: CGFloat

  /// Creates a focused-window placement request.
  ///
  /// - Parameters:
  ///   - placement: The target placement geometry. Grid values and centered ratios are clamped to
  ///     their executable ranges.
  ///   - screen: The screen selection rule. Non-finite point coordinates and negative ordered
  ///     indexes are normalized to zero.
  ///   - area: The screen area used for placement.
  ///   - inset: The inset applied to the placement frame. Negative or non-finite values are
  ///     normalized to `0`.
  public init(
    placement: ActionWindowPlacement,
    screen: ActionWindowScreenTarget = .containingWindow,
    area: ActionWindowScreenArea = .visible,
    inset: CGFloat = 0
  ) {
    self.placement = placement.normalized
    self.screen = screen.normalized
    self.area = area
    self.inset = Self.normalizedInset(inset)
  }

  private static func normalizedInset(_ inset: CGFloat) -> CGFloat {
    guard inset.isFinite else {
      return 0
    }
    return max(0, inset)
  }
}

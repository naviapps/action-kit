import CoreGraphics
import WindowKit

/// A request to place the focused window.
public struct WindowPlacementRequest: Sendable, Equatable, Hashable {
  /// The target placement geometry.
  public let placement: WindowPlacement
  /// The screen selection rule.
  public let screen: WindowScreenTarget
  /// The screen area used for placement.
  public let area: WindowScreenArea
  /// The inset applied to the placement frame.
  public let inset: CGFloat

  /// Creates a focused-window placement request.
  ///
  /// - Parameters:
  ///   - placement: The target placement geometry.
  ///   - screen: The screen selection rule.
  ///   - area: The screen area used for placement.
  ///   - inset: The inset applied to the placement frame. Negative or non-finite values are
  ///     normalized to `0`.
  public init(
    placement: WindowPlacement,
    screen: WindowScreenTarget = .containingWindow,
    area: WindowScreenArea = .visible,
    inset: CGFloat = 0
  ) {
    self.placement = placement
    self.screen = screen
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

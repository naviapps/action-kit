import ActionKit
import WindowKitAppKit

package enum FocusedWindowControlError: Error, Equatable, Sendable {
  case accessibilityNotTrusted
  case targetWindowUnavailable
  case invalidAccessibilityValue(String)
  case unsupportedAccessibilityOperation(String)
  case accessibilityOperationFailed(String)
  case screenNotFound(String)
  case unexpected(String)

  package init(_ error: WindowAccessibilityError) {
    switch error {
    case .accessibilityNotTrusted:
      self = .accessibilityNotTrusted
    case .applicationUnavailable, .windowUnavailable:
      self = .targetWindowUnavailable
    case .invalidAccessibilityValue(let operation):
      self = .invalidAccessibilityValue(operation.rawValue)
    case .unsupportedAccessibilityOperation(let operation):
      self = .unsupportedAccessibilityOperation(operation.rawValue)
    case let .accessibilityOperationFailed(operation, failure):
      self = .accessibilityOperationFailed("\(operation.rawValue): \(failure.rawValue)")
    }
  }

  package init(_ error: WindowPlacerError) {
    switch error {
    case .screenNotFound(let screen):
      self = .screenNotFound(String(describing: screen))
    }
  }
}

package protocol FocusedWindowControlling: Sendable {
  @MainActor
  func place(_ request: WindowPlacementRequest) throws(FocusedWindowControlError)

  @MainActor
  func moveToAdjacentScreen(_ request: WindowMoveRequest) throws(FocusedWindowControlError)
}

import ActionKit
import Foundation
@testable import ActionKitAppKit

final class TestFocusedWindowController: FocusedWindowControlling, @unchecked Sendable {
  private let lock = NSLock()
  private var placement: WindowPlacementRequest?
  private var move: WindowMoveRequest?
  private let placeError: (any Error & Sendable)?
  private let moveError: (any Error & Sendable)?

  init(
    placeError: (any Error & Sendable)? = nil,
    moveError: (any Error & Sendable)? = nil
  ) {
    self.placeError = placeError
    self.moveError = moveError
  }

  @MainActor
  func place(_ request: WindowPlacementRequest) throws {
    if let placeError {
      throw placeError
    }
    lock.withLock {
      placement = request
    }
  }

  @MainActor
  func moveToAdjacentScreen(_ request: WindowMoveRequest) throws {
    if let moveError {
      throw moveError
    }
    lock.withLock {
      move = request
    }
  }

  var recordedPlacement: WindowPlacementRequest? {
    lock.withLock {
      placement
    }
  }

  var recordedMove: WindowMoveRequest? {
    lock.withLock {
      move
    }
  }
}

import ActionKit
import Foundation
import ActionKitAppKit

final class TestFocusedWindowController: FocusedWindowControlling, @unchecked Sendable {
  private let lock = NSLock()
  private var placement: WindowPlacementRequest?
  private var move: WindowMoveRequest?
  private let placeError: FocusedWindowControlError?
  private let moveError: FocusedWindowControlError?

  init(
    placeError: FocusedWindowControlError? = nil,
    moveError: FocusedWindowControlError? = nil
  ) {
    self.placeError = placeError
    self.moveError = moveError
  }

  @MainActor
  func place(_ request: WindowPlacementRequest) throws(FocusedWindowControlError) {
    if let placeError {
      throw placeError
    }
    lock.withLock {
      placement = request
    }
  }

  @MainActor
  func moveToAdjacentScreen(_ request: WindowMoveRequest) throws(FocusedWindowControlError) {
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

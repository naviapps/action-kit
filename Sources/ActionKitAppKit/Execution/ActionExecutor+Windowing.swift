import ActionKit
import WindowKitAppKit

extension ActionExecutor {
  func executeWindowing(_ execution: WindowingExecution) async -> ActionResult {
    do {
      try await performWindowingExecution(execution)
      return .success
    } catch {
      return windowingResult(for: error)
    }
  }

  private func performWindowingExecution(_ execution: WindowingExecution)
    async throws(FocusedWindowControlError)
  {
    let controller = dependencies.makeFocusedWindowController()
    switch execution {
    case .placeFocusedWindow(let request):
      try await controller.place(request)
    case .moveFocusedWindow(let request):
      try await controller.moveToAdjacentScreen(request)
    }
  }

  private func windowingResult(for error: FocusedWindowControlError) -> ActionResult {
    switch error {
    case .accessibilityNotTrusted:
      return permissionDeniedResult(.accessibility)
    case .targetWindowUnavailable:
      return .skipped(.noFocusedWindow)
    case .invalidAccessibilityValue(let operation):
      return focusedWindowFailure(
        reason: "invalid Accessibility window value during \(operation)"
      )
    case .unsupportedAccessibilityOperation(let operation):
      return focusedWindowFailure(
        reason: "unsupported Accessibility window operation: \(operation)"
      )
    case .accessibilityOperationFailed(let error):
      return focusedWindowFailure(reason: "Accessibility window operation failed: \(error)")
    case .screenNotFound(let screen):
      return notFoundResult("Window screen not found: \(screen)")
    case .unexpected(let description):
      return focusedWindowFailure(reason: "unexpected error: \(description)")
    }
  }

  private func focusedWindowFailure(reason: String) -> ActionResult {
    internalErrorResult("Focused-window action failed: \(reason)")
  }
}

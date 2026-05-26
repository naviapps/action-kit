import ActionKit
import WindowKitAppKit

extension ActionExecutor {
  func executeWindowing(_ execution: WindowingExecution) async -> ActionResult {
    guard await configuration.permissions.ensureAccessibility() else {
      return .failure(.permissionDenied(.accessibility))
    }

    do {
      try await performWindowingExecution(execution)
      return .success
    } catch let error as AXWindowError {
      return windowingResult(for: error)
    } catch let error as WindowPlacerError {
      return windowingResult(for: error)
    } catch {
      return focusedWindowFailure(reason: "unexpected error: \(error)")
    }
  }

  private func performWindowingExecution(_ execution: WindowingExecution) async throws {
    try await MainActor.run {
      let controller = dependencies.makeFocusedWindowController()
      switch execution {
      case .placeFocusedWindow(let request):
        try controller.place(request)
      case .moveFocusedWindow(let request):
        try controller.moveToAdjacentScreen(request)
      }
    }
  }

  private func windowingResult(for error: AXWindowError) -> ActionResult {
    switch error {
    case .accessibilityNotTrusted:
      return .failure(.permissionDenied(.accessibility))
    case .applicationNotFound, .windowNotFound:
      return .skipped(.noFocusedWindow)
    case .invalidAXValue:
      return focusedWindowFailure(reason: "invalid Accessibility window value")
    case .unsupportedAction(let action):
      return focusedWindowFailure(reason: "unsupported Accessibility window action: \(action)")
    case .underlyingAccessibilityError(let error):
      return focusedWindowFailure(reason: "Accessibility window operation failed: \(error)")
    }
  }

  private func windowingResult(for error: WindowPlacerError) -> ActionResult {
    switch error {
    case .screenNotFound(let screen):
      let actionError = ActionError.notFound("Window screen not found: \(screen)")
      configuration.log(.error, actionError.diagnosticMessage)
      return .failure(actionError)
    }
  }

  private func focusedWindowFailure(reason: String) -> ActionResult {
    let actionError = ActionError.internalError("Focused-window action failed: \(reason)")
    configuration.log(.error, actionError.diagnosticMessage)
    return .failure(actionError)
  }
}

import ActionKit
import ApplicationServices
import Foundation

protocol KeyEventPosting: Sendable {
  func postKeyStroke(virtualKey: CGKeyCode, flags: CGEventFlags) -> Bool
}

protocol AppleScriptExecuting: Sendable {
  func execute(source: String) async -> Result<Void, AppleScriptExecutionFailure>
}

struct AppleScriptExecutionFailure: Error, Equatable, Sendable {
  let appleScriptErrorNumber: Int?
  let message: String?

  init(appleScriptErrorNumber: Int? = nil, message: String? = nil) {
    self.appleScriptErrorNumber = appleScriptErrorNumber
    self.message = message
  }
}

protocol SystemEventsLaunching: Sendable {
  func ensureRunning() async -> Bool
}

protocol ScreenCaptureProcessRunning: Sendable {
  func run(arguments: [String]) async -> Result<Void, ScreenCaptureProcessFailure>
}

struct ScreenCaptureProcessFailure: Error, Equatable, Sendable {
  let terminationStatus: Int32?

  init(terminationStatus: Int32? = nil) {
    self.terminationStatus = terminationStatus
  }
}

protocol ScreenCaptureAccessChecking: Sendable {
  func hasAccess() -> Bool
}

protocol WorkspaceControlling: Sendable {
  func open(_ url: URL) async -> Bool
  func urlForApplication(bundleIdentifier: String) async -> URL?
  func urlsForApplications(bundleIdentifier: String) async -> [URL]
  func urlForApplication(named name: String) async -> URL?
  func openApplication(at url: URL, activates: Bool) async throws
}

enum FrontmostApplicationControlResult: Sendable, Equatable {
  case success
  case noFrontmostApplication
  case failed
}

protocol FrontmostApplicationControlling: Sendable {
  func hideFrontmostApplication() async -> FrontmostApplicationControlResult
  func terminateFrontmostApplication() async -> FrontmostApplicationControlResult
}

protocol FocusedWindowControlling: Sendable {
  @MainActor
  func place(_ request: WindowPlacementRequest) throws

  @MainActor
  func moveToAdjacentScreen(_ request: WindowMoveRequest) throws
}

struct ActionExecutorDependencies: Sendable {
  let keyEventPoster: any KeyEventPosting
  let workspace: any WorkspaceControlling
  let frontmostApplicationController: any FrontmostApplicationControlling
  let appleScriptExecutor: any AppleScriptExecuting
  let systemEventsLauncher: any SystemEventsLaunching
  let screenCaptureProcessRunner: any ScreenCaptureProcessRunning
  let screenCaptureAccessChecker: any ScreenCaptureAccessChecking
  let makeFocusedWindowController: @Sendable () -> any FocusedWindowControlling
}

extension ActionExecutorDependencies {
  static var live: Self {
    .init(
      keyEventPoster: LiveKeyEventPoster(),
      workspace: LiveWorkspace(),
      frontmostApplicationController: LiveFrontmostApplicationController(),
      appleScriptExecutor: LiveAppleScriptExecutor(),
      systemEventsLauncher: LiveSystemEventsLauncher(),
      screenCaptureProcessRunner: LiveScreenCaptureProcessRunner(),
      screenCaptureAccessChecker: LiveScreenCaptureAccessChecker(),
      makeFocusedWindowController: { LiveFocusedWindowController() }
    )
  }
}

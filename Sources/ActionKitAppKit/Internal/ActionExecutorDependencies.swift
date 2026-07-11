package struct ActionExecutorDependencies: Sendable {
  let keyEventPoster: any KeyEventPosting
  let workspace: any WorkspaceControlling
  let frontmostApplicationController: any FrontmostApplicationControlling
  let appleScriptExecutor: any AppleScriptExecuting
  let systemEventsLauncher: any SystemEventsLaunching
  let screenCaptureProcessRunner: any ScreenCaptureProcessRunning
  let screenCaptureAccessChecker: any ScreenCaptureAccessChecking
  let makeFocusedWindowController: @Sendable () -> any FocusedWindowControlling

  package init(
    keyEventPoster: any KeyEventPosting,
    workspace: any WorkspaceControlling,
    frontmostApplicationController: any FrontmostApplicationControlling,
    appleScriptExecutor: any AppleScriptExecuting,
    systemEventsLauncher: any SystemEventsLaunching,
    screenCaptureProcessRunner: any ScreenCaptureProcessRunning,
    screenCaptureAccessChecker: any ScreenCaptureAccessChecking,
    makeFocusedWindowController: @escaping @Sendable () -> any FocusedWindowControlling
  ) {
    self.keyEventPoster = keyEventPoster
    self.workspace = workspace
    self.frontmostApplicationController = frontmostApplicationController
    self.appleScriptExecutor = appleScriptExecutor
    self.systemEventsLauncher = systemEventsLauncher
    self.screenCaptureProcessRunner = screenCaptureProcessRunner
    self.screenCaptureAccessChecker = screenCaptureAccessChecker
    self.makeFocusedWindowController = makeFocusedWindowController
  }
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

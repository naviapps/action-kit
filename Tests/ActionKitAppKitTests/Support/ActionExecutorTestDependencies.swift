import ActionKitAppKit

func makeActionExecutorDependencies(
  keyEventPoster: any KeyEventPosting = TestKeyEventPoster(),
  workspace: any WorkspaceControlling = TestWorkspace(),
  frontmostApplicationController: any FrontmostApplicationControlling =
    TestFrontmostApplicationController(),
  appleScriptExecutor: any AppleScriptExecuting = TestAppleScriptExecutor(),
  systemEventsLauncher: any SystemEventsLaunching = TestSystemEventsLauncher(),
  screenCaptureProcessRunner: any ScreenCaptureProcessRunning = TestScreenCaptureProcessRunner(),
  screenCaptureAccessChecker: any ScreenCaptureAccessChecking = TestScreenCaptureAccessChecker(),
  makeFocusedWindowController: @escaping @Sendable () -> any FocusedWindowControlling = {
    TestFocusedWindowController()
  }
) -> ActionExecutorDependencies {
  ActionExecutorDependencies(
    keyEventPoster: keyEventPoster,
    workspace: workspace,
    frontmostApplicationController: frontmostApplicationController,
    appleScriptExecutor: appleScriptExecutor,
    systemEventsLauncher: systemEventsLauncher,
    screenCaptureProcessRunner: screenCaptureProcessRunner,
    screenCaptureAccessChecker: screenCaptureAccessChecker,
    makeFocusedWindowController: makeFocusedWindowController
  )
}

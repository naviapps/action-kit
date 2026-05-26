import XCTest

@testable import ActionKitAppKit

final class ActionExecutorDependenciesTests: XCTestCase {
  func testLiveDependenciesUseLiveImplementations() {
    let deps = ActionExecutorDependencies.live

    XCTAssertTrue(deps.keyEventPoster is LiveKeyEventPoster)
    XCTAssertTrue(deps.workspace is LiveWorkspace)
    XCTAssertTrue(deps.frontmostApplicationController is LiveFrontmostApplicationController)
    XCTAssertTrue(deps.appleScriptExecutor is LiveAppleScriptExecutor)
    XCTAssertTrue(deps.systemEventsLauncher is LiveSystemEventsLauncher)
    XCTAssertTrue(deps.screenCaptureProcessRunner is LiveScreenCaptureProcessRunner)
    XCTAssertTrue(deps.screenCaptureAccessChecker is LiveScreenCaptureAccessChecker)
    XCTAssertTrue(deps.makeFocusedWindowController() is LiveFocusedWindowController)
  }
}

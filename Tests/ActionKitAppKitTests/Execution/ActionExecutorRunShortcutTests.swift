import XCTest

@testable import ActionKit
@testable import ActionKitAppKit

final class ActionExecutorRunShortcutTests: XCTestCase {
  func testRunShortcutBuildsShortcutsURL() async {
    let workspace = TestWorkspace()
    let dependencies = makeActionExecutorDependencies(workspace: workspace)
    let executor = ActionExecutor(configuration: .init(), dependencies: dependencies)

    let outcome = await executor.execute(.runShortcut("My Shortcut"))
    XCTAssertEqual(outcome.finalResult, ActionResult.success)

    guard let lastURL = await workspace.lastOpenedURL else {
      return XCTFail("Expected URL to be opened")
    }
    XCTAssertEqual(lastURL.scheme, "shortcuts")
    XCTAssertEqual(lastURL.host, "run-shortcut")
    XCTAssertEqual(
      URLComponents(url: lastURL, resolvingAgainstBaseURL: false)?.queryItems,
      [
        URLQueryItem(name: "name", value: "My Shortcut")
      ])
  }

  func testRunShortcutTrimsShortcutNameBeforeOpening() async {
    let workspace = TestWorkspace()
    let dependencies = makeActionExecutorDependencies(workspace: workspace)
    let executor = ActionExecutor(configuration: .init(), dependencies: dependencies)

    let outcome = await executor.execute(.runShortcut("  My Shortcut  "))
    XCTAssertEqual(outcome.finalResult, ActionResult.success)

    guard let lastURL = await workspace.lastOpenedURL else {
      return XCTFail("Expected URL to be opened")
    }
    XCTAssertEqual(
      URLComponents(url: lastURL, resolvingAgainstBaseURL: false)?.queryItems,
      [
        URLQueryItem(name: "name", value: "My Shortcut")
      ])
  }

  func testRunShortcutReturnsInvalidInputForEmptyName() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.runShortcut(" "))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .invalidInput)
    XCTAssertTrue(error.diagnosticMessage.contains("Empty shortcut name"))
    XCTAssertNil(lastOpenedURL)
  }

  func testRunShortcutReturnsOpenFailedWhenWorkspaceFails() async {
    let logs = LogRecorder()
    let workspace = TestWorkspace(openURLResult: false)
    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.runShortcut("My Shortcut"))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .openFailed)
    XCTAssertEqual(lastOpenedURL?.scheme, "shortcuts")
    XCTAssertEqual(lastOpenedURL?.host, "run-shortcut")
    XCTAssertTrue(error.diagnosticMessage.contains("Failed to run shortcut"))
    XCTAssertTrue(logs.contains(level: .error, message: "Failed to run shortcut"))
  }
}

import XCTest

import ActionKit
import ActionKitAppKit

final class ActionExecutorOpenURLTests: XCTestCase {
  func testOpenURLPassesAbsoluteURLToWorkspace() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openURL("https://example.com/path?q=1"))
    let lastOpenedURL = await workspace.lastOpenedURL

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(lastOpenedURL, URL(string: "https://example.com/path?q=1"))
  }

  func testOpenURLTrimsURLStringBeforeOpening() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openURL("  https://example.com/path  "))
    let lastOpenedURL = await workspace.lastOpenedURL

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(lastOpenedURL, URL(string: "https://example.com/path"))
  }

  func testOpenURLReturnsInvalidInputForEmptyValue() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openURL(" "))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .invalidInput)
    XCTAssertTrue(error.diagnosticMessage.contains("Invalid URL"))
    XCTAssertNil(lastOpenedURL)
  }

  func testOpenURLReturnsInvalidInputForRelativeURL() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openURL("example.com/path"))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .invalidInput)
    XCTAssertNil(lastOpenedURL)
  }

  func testOpenURLReturnsInvalidInputForHTTPURLWithoutHost() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openURL("https:example"))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .invalidInput)
    XCTAssertNil(lastOpenedURL)
  }

  func testOpenURLAllowsHostlessNonHTTPURL() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openURL("mailto:test@example.com"))
    let lastOpenedURL = await workspace.lastOpenedURL

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(lastOpenedURL, URL(string: "mailto:test@example.com"))
  }

  func testOpenURLReturnsOpenFailedWhenWorkspaceFails() async {
    let logs = LogRecorder()
    let workspace = TestWorkspace(openURLResult: false)
    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openURL("https://example.com"))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .openFailed)
    XCTAssertEqual(lastOpenedURL, URL(string: "https://example.com"))
    XCTAssertTrue(error.diagnosticMessage.contains("Failed to open URL"))
    XCTAssertTrue(logs.contains(level: .error, message: "Failed to open URL"))
  }
}

import XCTest

import ActionKit
import ActionKitAppKit

final class ActionExecutorOpenFolderTests: XCTestCase {
  func testOpenFolderPassesDirectoryURLToWorkspace() async throws {
    let tempURL = try makeTemporaryDirectory()
    let workspace = TestWorkspace()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openFolder(tempURL.path))
    let lastOpenedURL = await workspace.lastOpenedURL

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(lastOpenedURL?.standardized.path, tempURL.standardized.path)
  }

  func testOpenFolderExpandsTildeDirectoryPath() async {
    let directoryURL = FileManager.default.homeDirectoryForCurrentUser
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openFolder("~"))
    let lastOpenedURL = await workspace.lastOpenedURL

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(lastOpenedURL?.standardized.path, directoryURL.standardized.path)
  }

  func testOpenFolderReturnsInvalidInputForEmptyValue() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )
    let outcome = await executor.execute(.openFolder("   "))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(error.code, .invalidInput)
    XCTAssertTrue(error.diagnosticMessage.contains("Folder path is empty"))
    XCTAssertNil(lastOpenedURL)
  }

  func testOpenFolderReturnsNotFoundForMissingPath() async {
    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openFolder("/path/does/not/exist"))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .notFound)
    XCTAssertTrue(error.diagnosticMessage.contains("Folder does not exist"))
    XCTAssertNil(lastOpenedURL)
  }

  func testOpenFolderReturnsNotFoundForFilePath() async throws {
    let fileURL = try makeTemporaryFile()
    defer {
      try? FileManager.default.removeItem(at: fileURL)
    }

    let workspace = TestWorkspace()
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.openFolder(fileURL.path))
    let lastOpenedURL = await workspace.lastOpenedURL

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .notFound)
    XCTAssertTrue(error.diagnosticMessage.contains("Folder does not exist"))
    XCTAssertNil(lastOpenedURL)
  }

  func testOpenFolderReturnsOpenFailedWhenWorkspaceFails() async throws {
    let tempURL = try makeTemporaryDirectory()
    let logs = LogRecorder()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }

    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: makeActionExecutorDependencies(
        workspace: TestWorkspace(openURLResult: false)
      )
    )

    let outcome = await executor.execute(.openFolder(tempURL.path))
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .openFailed)
    XCTAssertTrue(error.diagnosticMessage.contains("Failed to open folder"))
    XCTAssertTrue(logs.contains(level: .error, message: "Failed to open folder"))
  }
}

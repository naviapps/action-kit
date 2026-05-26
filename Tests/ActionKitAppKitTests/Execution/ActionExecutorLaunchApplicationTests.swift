import XCTest

@testable import ActionKit
@testable import ActionKitAppKit

final class ActionExecutorLaunchApplicationTests: XCTestCase {
  func testLaunchApplicationReturnsInvalidInputForEmptyValue() async {
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies()
    )

    let outcome = await executor.execute(.launchApplication(" "))
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .invalidInput)
    XCTAssertTrue(error.diagnosticMessage.contains("Empty application"))
  }

  func testLaunchApplicationReturnsOpenFailedWhenBundleLaunchThrows() async throws {
    let tempURL = try makeTemporaryDirectory()
    let logs = LogRecorder()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }

    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: makeActionExecutorDependencies(
        workspace: TestWorkspace(
          applicationURLForBundleIdentifier: tempURL,
          openApplicationError: TestApplicationOpenError()
        )
      )
    )

    let outcome = await executor.execute(.launchApplication("com.example.app"))
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .openFailed)
    XCTAssertTrue(error.diagnosticMessage.contains("bundle identifier"))
    XCTAssertTrue(
      logs.contains(level: .error, message: "Failed to launch application by bundle identifier")
    )
  }

  func testLaunchApplicationReturnsOpenFailedWhenPathLaunchThrows() async throws {
    let tempURL = try makeTemporaryApplicationBundleDirectory()
    let logs = LogRecorder()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }

    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: makeActionExecutorDependencies(
        workspace: TestWorkspace(
          applicationURLForBundleIdentifier: nil,
          applicationURLsForBundleIdentifier: [],
          openApplicationError: TestApplicationOpenError()
        )
      )
    )

    let outcome = await executor.execute(.launchApplication(tempURL.path))
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .openFailed)
    XCTAssertTrue(error.diagnosticMessage.contains("Failed to launch application at path"))
    XCTAssertTrue(logs.contains(level: .error, message: "Failed to launch application at path"))
  }

  func testLaunchApplicationUsesExistingPathBeforeBundleIdentifierLookup() async throws {
    let tempURL = try makeTemporaryApplicationBundleDirectory()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: URL(fileURLWithPath: "/Applications/Other.app"))
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication(tempURL.path))
    let snapshot = await workspace.applicationLaunchSnapshot

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(snapshot.openedApplicationURL?.standardized.path, tempURL.standardized.path)
    XCTAssertEqual(snapshot.openedApplicationActivates, true)
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, [])
    XCTAssertEqual(snapshot.resolvedApplicationNames, [])
  }

  func testLaunchApplicationExpandsTildeApplicationPath() async throws {
    let appName = ".action-kit-\(UUID().uuidString).app"
    let appURL = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(appName)
    try FileManager.default.createDirectory(at: appURL, withIntermediateDirectories: true)
    defer {
      try? FileManager.default.removeItem(at: appURL)
    }
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: URL(fileURLWithPath: "/Applications/Other.app"))
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication("~/\(appName)"))
    let snapshot = await workspace.applicationLaunchSnapshot

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(snapshot.openedApplicationURL?.standardized.path, appURL.standardized.path)
    XCTAssertEqual(snapshot.openedApplicationActivates, true)
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, [])
    XCTAssertEqual(snapshot.resolvedApplicationNames, [])
  }

  func testLaunchApplicationRejectsExistingNonApplicationPath() async throws {
    let tempURL = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: URL(fileURLWithPath: "/Applications/Other.app"))
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication(tempURL.path))
    let snapshot = await workspace.applicationLaunchSnapshot

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .invalidInput)
    XCTAssertTrue(error.diagnosticMessage.contains(".app bundle"))
    XCTAssertNil(snapshot.openedApplicationURL)
    XCTAssertNil(snapshot.openedApplicationActivates)
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, [])
    XCTAssertEqual(snapshot.resolvedApplicationNames, [])
  }

  func testLaunchApplicationReturnsNotFoundForMissingApplicationPath() async {
    let missingURL = FileManager.default.temporaryDirectory
      .appendingPathComponent(UUID().uuidString)
      .appendingPathExtension("app")
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: URL(fileURLWithPath: "/Applications/Other.app"),
      applicationURLForName: URL(fileURLWithPath: "/Applications/Other.app")
    )
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication(missingURL.path))
    let snapshot = await workspace.applicationLaunchSnapshot

    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .notFound)
    XCTAssertTrue(error.diagnosticMessage.contains("Application path does not exist"))
    XCTAssertNil(snapshot.openedApplicationURL)
    XCTAssertNil(snapshot.openedApplicationActivates)
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, [])
    XCTAssertEqual(snapshot.resolvedApplicationNames, [])
  }

  func testLaunchApplicationResolvesApplicationNameBeforeBundleIdentifierLookup() async throws {
    let tempURL = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: nil,
      applicationURLsForBundleIdentifier: [],
      applicationURLForName: tempURL
    )
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication("Safari"))
    let snapshot = await workspace.applicationLaunchSnapshot

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(snapshot.openedApplicationURL?.standardized.path, tempURL.standardized.path)
    XCTAssertEqual(snapshot.openedApplicationActivates, true)
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, [])
    XCTAssertEqual(snapshot.resolvedApplicationNames, ["Safari"])
  }

  func testLaunchApplicationFallsBackToBundleIdentifierWhenNameLookupMisses() async throws {
    let tempURL = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: tempURL,
      applicationURLForName: nil
    )
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication("Safari"))
    let snapshot = await workspace.applicationLaunchSnapshot

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(snapshot.openedApplicationURL?.standardized.path, tempURL.standardized.path)
    XCTAssertEqual(snapshot.openedApplicationActivates, true)
    XCTAssertEqual(snapshot.resolvedApplicationNames, ["Safari"])
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, ["Safari"])
  }

  func testLaunchApplicationResolvesBundleIdentifierBeforeApplicationName() async throws {
    let tempURL = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: tempURL,
      applicationURLForName: URL(fileURLWithPath: "/Applications/Other.app")
    )
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication("com.example.app"))
    let snapshot = await workspace.applicationLaunchSnapshot

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(snapshot.openedApplicationURL?.standardized.path, tempURL.standardized.path)
    XCTAssertEqual(snapshot.openedApplicationActivates, true)
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, ["com.example.app"])
    XCTAssertEqual(snapshot.resolvedApplicationNames, [])
  }

  func testLaunchApplicationUsesFirstBundleIdentifierCandidateWhenPrimaryLookupMisses()
    async throws
  {
    let tempURL = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: nil,
      applicationURLsForBundleIdentifier: [tempURL],
      applicationURLForName: URL(fileURLWithPath: "/Applications/Other.app")
    )
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication("com.example.app"))
    let snapshot = await workspace.applicationLaunchSnapshot

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(snapshot.openedApplicationURL?.standardized.path, tempURL.standardized.path)
    XCTAssertEqual(snapshot.openedApplicationActivates, true)
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, ["com.example.app", "com.example.app"])
    XCTAssertEqual(snapshot.resolvedApplicationNames, [])
  }

  func testLaunchApplicationFallsBackToApplicationNameWhenBundleIdentifierLookupMisses()
    async throws
  {
    let tempURL = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }
    let workspace = TestWorkspace(
      applicationURLForBundleIdentifier: nil,
      applicationURLsForBundleIdentifier: [],
      applicationURLForName: tempURL
    )
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(workspace: workspace)
    )

    let outcome = await executor.execute(.launchApplication("Preview.app"))
    let snapshot = await workspace.applicationLaunchSnapshot

    XCTAssertEqual(outcome.finalResult, .success)
    XCTAssertEqual(snapshot.openedApplicationURL?.standardized.path, tempURL.standardized.path)
    XCTAssertEqual(snapshot.openedApplicationActivates, true)
    XCTAssertEqual(snapshot.resolvedBundleIdentifiers, ["Preview.app", "Preview.app"])
    XCTAssertEqual(snapshot.resolvedApplicationNames, ["Preview.app"])
  }

  func testLaunchApplicationReturnsNotFoundWhenNoCandidateFound() async {
    let executor = ActionExecutor(
      configuration: .init(),
      dependencies: makeActionExecutorDependencies(
        workspace: TestWorkspace(
          applicationURLForBundleIdentifier: nil,
          applicationURLsForBundleIdentifier: []
        )
      )
    )

    let outcome = await executor.execute(.launchApplication("com.example.missing"))
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .notFound)
    XCTAssertTrue(error.diagnosticMessage.contains("Unable to resolve application"))
  }

  func testLaunchApplicationReturnsOpenFailedWhenNameLaunchThrows() async throws {
    let tempURL = try makeTemporaryDirectory()
    let logs = LogRecorder()
    defer {
      try? FileManager.default.removeItem(at: tempURL)
    }

    let executor = ActionExecutor(
      configuration: .init(log: { level, message in logs.record(level, message) }),
      dependencies: makeActionExecutorDependencies(
        workspace: TestWorkspace(
          applicationURLForName: tempURL,
          openApplicationError: TestApplicationOpenError()
        )
      )
    )

    let outcome = await executor.execute(.launchApplication("Safari"))
    guard case .failure(let error) = outcome.finalResult else {
      return XCTFail("Expected failure, got: \(outcome.finalResult)")
    }
    XCTAssertEqual(error.code, .openFailed)
    XCTAssertTrue(error.diagnosticMessage.contains("Failed to launch application by name"))
    XCTAssertTrue(logs.contains(level: .error, message: "Failed to launch application by name"))
  }
}

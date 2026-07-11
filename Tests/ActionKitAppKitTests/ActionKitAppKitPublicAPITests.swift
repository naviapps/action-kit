import ActionKit
import ActionKitAppKit
import Foundation
import XCTest

final class ActionKitAppKitPublicAPITests: XCTestCase {
  func testExecutorConfigurationAPIsAreUsableWithoutTestableImport() async {
    let logRecorder = PublicAPILogRecorder()
    let permissions = ActionExecutorConfiguration.Permissions(
      ensureAccessibility: { true },
      ensureAutomation: { true },
      onAutomationDenied: { _ in },
      onScreenRecordingRequired: {}
    )
    let configuration = ActionExecutorConfiguration(
      permissions: permissions,
      log: { level, message in
        logRecorder.record(level, message)
      }
    )

    configuration.log(.info, "ready")
    let accessibilityReady = await configuration.permissions.ensureAccessibility()
    let automationReady = await configuration.permissions.ensureAutomation()
    let logEntries = logRecorder.entries()

    XCTAssertTrue(accessibilityReady)
    XCTAssertTrue(automationReady)
    XCTAssertEqual(logEntries.count, 1)
    XCTAssertEqual(logEntries.first?.0, .info)
    XCTAssertEqual(logEntries.first?.1, "ready")
    XCTAssertEqual(
      ActionExecutorConfiguration.LogLevel.allCases,
      [.debug, .info, .warning, .error]
    )
  }

  func testExecutorCanBeCreatedWithoutTestableImport() {
    let executor = ActionExecutor(configuration: ActionExecutorConfiguration())
    let execute: (Action) async -> ActionOutcome = executor.execute

    _ = executor
    _ = execute
  }

  func testDocCExecutorSampleSignatureIsUsableWithoutTestableImport() {
    let executor = ActionExecutor()
    let execute: (Action) async -> ActionOutcome = executor.execute

    _ = executor
    _ = execute
  }

  func testREADMEExecutionSampleSignatureIsUsableWithoutTestableImport() {
    let executor = ActionExecutor()
    let request = WindowPlacementRequest(
      placement: .grid(columns: 2, rows: 1, column: 1, row: 0, columnSpan: 1, rowSpan: 1)
    )
    let action = Action.windowPlacement(request)
    let execute: (Action) async -> ActionOutcome = executor.execute

    XCTAssertEqual(action, .windowPlacement(request))
    _ = execute
  }

  func testLogLevelCodableAPIIsUsableWithoutTestableImport() throws {
    let data = try JSONEncoder().encode(ActionExecutorConfiguration.LogLevel.warning)
    let decoded = try JSONDecoder().decode(ActionExecutorConfiguration.LogLevel.self, from: data)

    XCTAssertEqual(decoded, .warning)
  }

  func testPublicValueConformancesAreUsableWithoutTestableImport() throws {
    let permissions = ActionExecutorConfiguration.Permissions(
      ensureAccessibility: { true },
      ensureAutomation: { true },
      onAutomationDenied: { _ in },
      onScreenRecordingRequired: {}
    )
    let configuration = ActionExecutorConfiguration(permissions: permissions)

    try assertCodableHashableSendable(
      ActionExecutorConfiguration.LogLevel.self,
      ActionExecutorConfiguration.LogLevel.warning
    )
    assertSendable(ActionExecutorConfiguration.Permissions.self, permissions)
    assertSendable(ActionExecutorConfiguration.self, configuration)
  }
}

private final class PublicAPILogRecorder: @unchecked Sendable {
  private let lock = NSLock()
  private var recordedEntries: [(ActionExecutorConfiguration.LogLevel, String)] = []

  func record(_ level: ActionExecutorConfiguration.LogLevel, _ message: String) {
    lock.withLock {
      recordedEntries.append((level, message))
    }
  }

  func entries() -> [(ActionExecutorConfiguration.LogLevel, String)] {
    lock.withLock {
      recordedEntries
    }
  }
}

private func assertCodableHashableSendable<T>(
  _: T.Type,
  _ value: T,
  file: StaticString = #filePath,
  line: UInt = #line
) throws where T: Codable & Hashable & Sendable {
  let decoded = try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))

  XCTAssertEqual(decoded, value, file: file, line: line)
  assertSendable(T.self, value)
}

private func assertSendable<T>(
  _: T.Type,
  _ value: T,
  file: StaticString = #filePath,
  line: UInt = #line
) where T: Sendable {
  _ = value
  XCTAssertTrue(true, file: file, line: line)
}

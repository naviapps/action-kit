import ApplicationServices
import XCTest

import ActionKitAppKit

@MainActor
final class ActionExecutorConfigurationTests: XCTestCase {
  func testDefaultConfigurationClosuresUseSystemSafeDefaults() async {
    let configuration = ActionExecutorConfiguration()
    let accessibility = await configuration.permissions.ensureAccessibility()
    let automation = await configuration.permissions.ensureAutomation()

    XCTAssertEqual(accessibility, AXIsProcessTrusted())
    XCTAssertTrue(automation)
    await configuration.permissions.onAutomationDenied(nil)
    await configuration.permissions.onScreenRecordingRequired()
  }

  func testLogLevelsRoundTripCodableRawValue() throws {
    for level in ActionExecutorConfiguration.LogLevel.allCases {
      let data = try JSONEncoder().encode(level)
      XCTAssertEqual(
        try JSONDecoder().decode(ActionExecutorConfiguration.LogLevel.self, from: data),
        level
      )
    }
  }

  func testLogLevelCasesAreCanonical() {
    XCTAssertEqual(
      ActionExecutorConfiguration.LogLevel.allCases,
      [
        .debug,
        .info,
        .warning,
        .error,
      ]
    )
  }

  func testLogLevelRawValuesAreCanonical() {
    XCTAssertEqual(
      ActionExecutorConfiguration.LogLevel.allCases.map(\.rawValue),
      [
        "debug",
        "info",
        "warning",
        "error",
      ]
    )
  }

  func testCustomLogHookIsUsed() {
    let recorder = LogRecorder()
    let configuration = ActionExecutorConfiguration(
      log: { level, message in
        recorder.record(level, message)
      }
    )

    configuration.log(.warning, "Permission check failed")

    XCTAssertTrue(recorder.contains(level: .warning, message: "Permission check failed"))
  }

  func testCustomPermissionHooksAreUsed() async {
    var accessibilityHookCalled = false
    var automationHookCalled = false
    var automationDeniedErrorNumber: Int?
    var screenRecordingHookCalled = false

    let configuration = ActionExecutorConfiguration(
      permissions: .init(
        ensureAccessibility: {
          accessibilityHookCalled = true
          return false
        },
        ensureAutomation: {
          automationHookCalled = true
          return false
        },
        onAutomationDenied: { appleScriptErrorNumber in
          automationDeniedErrorNumber = appleScriptErrorNumber
        },
        onScreenRecordingRequired: {
          screenRecordingHookCalled = true
        }
      )
    )

    let accessibilityReady = await configuration.permissions.ensureAccessibility()
    let automationReady = await configuration.permissions.ensureAutomation()
    await configuration.permissions.onAutomationDenied(-1743)
    await configuration.permissions.onScreenRecordingRequired()

    XCTAssertFalse(accessibilityReady)
    XCTAssertFalse(automationReady)
    XCTAssertTrue(accessibilityHookCalled)
    XCTAssertTrue(automationHookCalled)
    XCTAssertEqual(automationDeniedErrorNumber, -1743)
    XCTAssertTrue(screenRecordingHookCalled)
  }
}

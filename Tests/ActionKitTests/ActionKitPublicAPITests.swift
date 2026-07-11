import ActionKit
import CoreGraphics
import Foundation
import XCTest

final class ActionKitPublicAPITests: XCTestCase {
  func testDocCActionKindCatalogSampleIsUsableWithoutTestableImport() throws {
    let kind: ActionKind = .openURL
    let identifier = kind.identifier
    let inputDescriptor: ActionInputDescriptor = kind.inputDescriptor
    let inputShape: ActionInputShape = inputDescriptor.shape
    let parameterName = inputDescriptor.parameter?.name
    let exampleInput = inputDescriptor.exampleInput
    let requiresInput = inputDescriptor.requiresInput
    let capabilities: ActionKindCapabilities = kind.capabilities
    let explicitCapabilities = ActionKindCapabilities(
      requiresFrontmostApplication: true,
      requiresFocusedWindow: true,
      requiresInteractiveSelection: false,
      isDestructive: false,
      retryBehavior: .contextDependent
    )
    let permissionSet: ActionPermissionSet = ActionPreflight.permissions(forKind: kind)
    let permissionHints: [ActionPermissionHint] = ActionPreflight.permissionHints(forKind: kind)

    XCTAssertEqual(identifier, "action.workspace.open-url")
    XCTAssertEqual(ActionKind(identifier: identifier), kind)
    XCTAssertEqual(inputShape, .string)
    XCTAssertEqual(kind.category, .workspace)
    XCTAssertEqual(parameterName, "url")
    XCTAssertEqual(exampleInput, .string("https://example.com"))
    XCTAssertTrue(requiresInput)
    XCTAssertFalse(capabilities.requiresFrontmostApplication)
    XCTAssertFalse(capabilities.requiresFocusedWindow)
    XCTAssertFalse(capabilities.requiresInteractiveSelection)
    XCTAssertFalse(capabilities.isDestructive)
    XCTAssertEqual(capabilities.retryBehavior, ActionRetryBehavior.unsafe)
    XCTAssertTrue(explicitCapabilities.requiresFrontmostApplication)
    XCTAssertTrue(explicitCapabilities.requiresFocusedWindow)
    XCTAssertEqual(explicitCapabilities.retryBehavior, .contextDependent)
    XCTAssertTrue(permissionSet.isEmpty)
    XCTAssertTrue(permissionHints.isEmpty)
  }

  func testDocCActionCreationSampleIsUsableWithoutTestableImport() throws {
    let action = try XCTUnwrap(
      ActionKind.openURL.makeAction(input: .string("https://example.com"))
    )

    XCTAssertEqual(action, .openURL("https://example.com"))
  }

  func testREADMECapabilitiesSampleIsUsableWithoutTestableImport() {
    let capabilities = ActionKind.windowPlacement.capabilities

    XCTAssertTrue(capabilities.requiresFocusedWindow)
    XCTAssertFalse(capabilities.requiresInteractiveSelection)
    XCTAssertFalse(capabilities.isDestructive)
    XCTAssertEqual(capabilities.retryBehavior, .safe)
  }

  func testREADMEWindowingSampleIsUsableWithoutTestableImport() throws {
    let request = WindowPlacementRequest(
      placement: .grid(columns: 2, rows: 1, column: 0, row: 0, columnSpan: 1, rowSpan: 1),
      screen: .containingWindow,
      area: .visible,
      inset: 8
    )
    let action = Action.windowPlacement(request)
    let data = try JSONEncoder().encode(request)
    let decoded = try JSONDecoder().decode(WindowPlacementRequest.self, from: data)

    XCTAssertEqual(action, .windowPlacement(request))
    XCTAssertEqual(decoded, request)
  }

  func testPublicContractTypesAreUsableWithoutTestableImport() throws {
    let parameter = try XCTUnwrap(
      ActionInputParameter(
        name: "text",
        description: "Text to type",
        exampleInput: .string("Hello")
      )
    )
    let descriptor = try XCTUnwrap(
      ActionInputDescriptor(shape: .string, parameter: parameter)
    )
    let placementRequest = WindowPlacementRequest(
      placement: ActionWindowPlacement.centered(widthRatio: 0.7, heightRatio: 0.5),
      screen: ActionWindowScreenTarget.point(CGPoint(x: 24, y: 36)),
      area: ActionWindowScreenArea.visible,
      inset: 8
    )
    let moveRequest = WindowMoveRequest(
      direction: ActionWindowScreenCycleDirection.next,
      preservesRelativePosition: false
    )
    let action = try XCTUnwrap(ActionKind.openURL.makeAction(input: ActionInput.string("url")))
    let actionError = ActionError.permissionDenied(ActionPermission.accessibility)
    let skipReason = ActionSkipReason.noFocusedWindow
    let result = ActionResult.failure(actionError)
    let outcome = try decodePublicOutcome()
    let attempt = try XCTUnwrap(outcome.attempts.first)
    let codecData = try ActionCodec.encode(action)
    let codecError = ActionCodecError.unsupportedVersion(0)

    XCTAssertEqual(try ActionCodec.decode(codecData), action)
    XCTAssertEqual(ActionCodec.currentVersion, 1)
    XCTAssertEqual(ActionCategory.workspace, .workspace)
    XCTAssertEqual(ActionInputShape.string, descriptor.shape)
    XCTAssertEqual(ActionPermissionReason.accessibilityWindowing, .accessibilityWindowing)
    XCTAssertEqual(
      ActionPermissionSet(primary: [.accessibility], fallback: []).primary,
      [.accessibility]
    )
    XCTAssertEqual(
      ActionPermissionHint(permission: .accessibility, reason: .accessibility).reason,
      .accessibility
    )
    XCTAssertEqual(ActionErrorCode.permissionDenied, actionError.code)
    XCTAssertEqual(ActionResult.skipped(skipReason), .skipped(.noFocusedWindow))
    XCTAssertEqual(result, .failure(actionError))
    XCTAssertEqual(outcome.finalResult, .skipped(.noFocusedWindow))
    XCTAssertEqual(attempt.result, .skipped(.noFocusedWindow))
    XCTAssertEqual(codecError.errorDescription, "Unsupported action envelope version: 0.")

    try assertCodableHashableSendable(Action.self, action)
    try assertCodableHashableSendable(ActionAttempt.self, attempt)
    try assertCodableHashableSendable(ActionCategory.self, ActionCategory.workspace)
    try assertCodableHashableSendable(ActionError.self, actionError)
    try assertCodableHashableSendable(ActionErrorCode.self, ActionErrorCode.permissionDenied)
    try assertCodableHashableSendable(
      ActionInput.self, ActionInput.windowPlacement(placementRequest))
    try assertCodableHashableSendable(ActionInputDescriptor.self, descriptor)
    try assertCodableHashableSendable(ActionInputParameter.self, parameter)
    try assertCodableHashableSendable(ActionInputShape.self, ActionInputShape.string)
    try assertCodableHashableSendable(ActionKind.self, ActionKind.openURL)
    try assertCodableHashableSendable(ActionKindCapabilities.self, ActionKind.openURL.capabilities)
    try assertCodableHashableSendable(ActionOutcome.self, outcome)
    try assertCodableHashableSendable(ActionPermission.self, ActionPermission.accessibility)
    try assertCodableHashableSendable(
      ActionPermissionHint.self,
      ActionPermissionHint(permission: .accessibility, reason: .accessibility)
    )
    try assertCodableHashableSendable(ActionPermissionReason.self, .accessibilityWindowing)
    try assertCodableHashableSendable(
      ActionPermissionSet.self,
      ActionPermissionSet(primary: [.accessibility], fallback: [.screenRecording])
    )
    try assertCodableHashableSendable(ActionResult.self, result)
    try assertCodableHashableSendable(ActionRetryBehavior.self, ActionRetryBehavior.safe)
    try assertCodableHashableSendable(ActionSkipReason.self, skipReason)
    try assertCodableHashableSendable(ActionWindowPlacement.self, placementRequest.placement)
    try assertCodableHashableSendable(ActionWindowScreenArea.self, placementRequest.area)
    try assertCodableHashableSendable(ActionWindowScreenCycleDirection.self, moveRequest.direction)
    try assertCodableHashableSendable(ActionWindowScreenTarget.self, placementRequest.screen)
    try assertCodableHashableSendable(WindowMoveRequest.self, moveRequest)
    try assertCodableHashableSendable(WindowPlacementRequest.self, placementRequest)
    assertHashableSendable(ActionCodecError.self, codecError)
    assertLocalizedError(codecError)
    assertLocalizedError(actionError)
  }
}

private func decodePublicOutcome() throws -> ActionOutcome {
  let data = """
    {
      "finalResult": { "status": "skipped", "skipReason": "no-focused-window" },
      "attempts": [
        {
          "requiredPermissions": ["accessibility"],
          "isFallback": false,
          "result": { "status": "skipped", "skipReason": "no-focused-window" }
        }
      ]
    }
    """.data(using: .utf8)!

  return try JSONDecoder().decode(ActionOutcome.self, from: data)
}

private func assertCodableHashableSendable<T>(
  _: T.Type,
  _ value: T,
  file: StaticString = #filePath,
  line: UInt = #line
) throws where T: Codable & Hashable & Sendable {
  let decoded = try JSONDecoder().decode(T.self, from: JSONEncoder().encode(value))

  XCTAssertEqual(decoded, value, file: file, line: line)
  assertHashableSendable(T.self, value, file: file, line: line)
}

private func assertHashableSendable<T>(
  _: T.Type,
  _ value: T,
  file: StaticString = #filePath,
  line: UInt = #line
) where T: Hashable & Sendable {
  var hasher = Hasher()
  value.hash(into: &hasher)

  XCTAssertEqual(value, value, file: file, line: line)
  XCTAssertEqual(value.hashValue, value.hashValue, file: file, line: line)
}

private func assertLocalizedError<T>(
  _ value: T,
  file: StaticString = #filePath,
  line: UInt = #line
) where T: Error & LocalizedError & Hashable & Sendable {
  XCTAssertEqual(value, value, file: file, line: line)
  XCTAssertNotNil(value.errorDescription, file: file, line: line)
}

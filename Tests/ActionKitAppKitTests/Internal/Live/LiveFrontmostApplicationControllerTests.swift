import XCTest

@testable import ActionKitAppKit

final class LiveFrontmostApplicationControllerTests: XCTestCase {
  func testHideFrontmostApplicationReturnsInjectedResult() async {
    let hideInvocations = InvocationRecorder()
    let terminateInvocations = InvocationRecorder()
    let controller = LiveFrontmostApplicationController(
      hideFrontmost: {
        hideInvocations.record()
        return .noFrontmostApplication
      },
      terminateFrontmost: {
        terminateInvocations.record()
        return .success
      }
    )

    let result = await controller.hideFrontmostApplication()

    XCTAssertEqual(result, .noFrontmostApplication)
    XCTAssertEqual(hideInvocations.invocationCount, 1)
    XCTAssertEqual(terminateInvocations.invocationCount, 0)
  }

  func testTerminateFrontmostApplicationReturnsInjectedResult() async {
    let hideInvocations = InvocationRecorder()
    let terminateInvocations = InvocationRecorder()
    let controller = LiveFrontmostApplicationController(
      hideFrontmost: {
        hideInvocations.record()
        return .success
      },
      terminateFrontmost: {
        terminateInvocations.record()
        return .failed
      }
    )

    let result = await controller.terminateFrontmostApplication()

    XCTAssertEqual(result, .failed)
    XCTAssertEqual(hideInvocations.invocationCount, 0)
    XCTAssertEqual(terminateInvocations.invocationCount, 1)
  }
}

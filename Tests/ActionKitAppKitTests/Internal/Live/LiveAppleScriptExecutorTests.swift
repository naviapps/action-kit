import XCTest

@testable import ActionKitAppKit

final class LiveAppleScriptExecutorTests: XCTestCase {
  func testExecuteSucceedsForValidScript() async {
    let executor = LiveAppleScriptExecutor()
    let result = await executor.execute(source: "return 1")
    guard case .success = result else {
      return XCTFail("Expected success")
    }
  }

  func testExecutePreservesCompileErrorDetails() async {
    let executor = LiveAppleScriptExecutor()
    let result = await executor.execute(source: "not valid applescript")
    switch result {
    case .success:
      XCTFail("Expected failure")
    case .failure(let failure):
      XCTAssertEqual(failure.appleScriptErrorNumber, -2740)
      XCTAssertFalse(failure.message?.isEmpty ?? true)
    }
  }

  func testExecutePreservesRuntimeErrorDetails() async {
    let executor = LiveAppleScriptExecutor()
    let result = await executor.execute(source: #"error "boom" number 1234"#)

    switch result {
    case .success:
      XCTFail("Expected failure")
    case .failure(let failure):
      XCTAssertEqual(failure.appleScriptErrorNumber, 1234)
      XCTAssertEqual(failure.message, "boom")
    }
  }
}

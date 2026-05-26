import Foundation
import XCTest

@testable import ActionKitAppKit

final class LiveScreenCaptureProcessRunnerTests: XCTestCase {
  func testRunReturnsSuccessForZeroExitStatus() async {
    let runner = LiveScreenCaptureProcessRunner(
      executableURL: URL(fileURLWithPath: "/usr/bin/true")
    )

    guard case .success = await runner.run(arguments: []) else {
      return XCTFail("Expected success")
    }
  }

  func testRunPassesArgumentsToProcess() async throws {
    let directory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: directory)
    }
    let outputURL = directory.appendingPathComponent("arguments.txt")
    let scriptURL = directory.appendingPathComponent("record-arguments.sh")
    let script = """
      #!/bin/sh
      printf '%s\\n' "$@" > "\(outputURL.path)"
      """
    try script.write(to: scriptURL, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes(
      [.posixPermissions: 0o755],
      ofItemAtPath: scriptURL.path
    )
    let runner = LiveScreenCaptureProcessRunner(executableURL: scriptURL)

    guard case .success = await runner.run(arguments: ["-i", "-W"]) else {
      return XCTFail("Expected success")
    }

    let output = try String(contentsOf: outputURL, encoding: .utf8)
    XCTAssertEqual(output, "-i\n-W\n")
  }

  func testRunReturnsTerminationStatusForNonzeroExitStatus() async {
    let runner = LiveScreenCaptureProcessRunner(
      executableURL: URL(fileURLWithPath: "/usr/bin/false")
    )

    guard case .failure(let failure) = await runner.run(arguments: []) else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(failure, .init(terminationStatus: 1))
  }

  func testRunReturnsFailureWithoutStatusWhenProcessCannotLaunch() async {
    let runner = LiveScreenCaptureProcessRunner(
      executableURL: URL(fileURLWithPath: "/path/does/not/exist")
    )

    guard case .failure(let failure) = await runner.run(arguments: []) else {
      return XCTFail("Expected failure")
    }
    XCTAssertEqual(failure, .init(terminationStatus: nil))
  }
}

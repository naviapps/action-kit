import Darwin
import Foundation
import XCTest

@testable import ActionKitAppKit

@MainActor
final class ShortcutsCatalogTests: XCTestCase {
  func testMissingExecutableReportsUnavailable() async {
    await assertFailure(
      .unavailable,
      catalog: ShortcutsCatalog(executableURL: URL(fileURLWithPath: "/missing-shortcuts-\(UUID())"))
    )
  }

  func testNonzeroExitDoesNotExposeStderr() async throws {
    let fixture = try executable("echo private-diagnostic >&2\nexit 1")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    await assertFailure(.executionFailed, catalog: ShortcutsCatalog(executableURL: fixture))
  }

  func testNamesPreserveCaseHeaderLikeNamesAndLeadingDashes() async throws {
    let fixture = try executable("printf 'Name\\n-Work\\nbeta\\nBeta\\n名前\\nbeta\\n\\n'")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    let names = try await ShortcutsCatalog(executableURL: fixture).shortcutNames()
    XCTAssertEqual(Set(names), Set(["Name", "-Work", "beta", "Beta", "名前"]))
    XCTAssertEqual(names.count, 5)
    XCTAssertTrue(names.firstIndex(of: "Beta")! < names.firstIndex(of: "beta")!)
  }

  func testOutputLargerThanPipeBufferIsDrainedBeforeWaitingForExit() async throws {
    let fixture = try executable(
      "/usr/bin/awk 'BEGIN { for (i=0; i<30000; i++) print \"Alpha\"; }'")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    let names = try await ShortcutsCatalog(executableURL: fixture, timeout: .seconds(5))
      .shortcutNames()
    XCTAssertEqual(names, ["Alpha"])
  }

  func testLargeStderrCannotBlockListing() async throws {
    let fixture = try executable(
      "/usr/bin/awk 'BEGIN { for (i=0; i<30000; i++) print \"ignored\"; }' >&2\nprintf 'Alpha\\n'")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    let names = try await ShortcutsCatalog(executableURL: fixture, timeout: .seconds(5))
      .shortcutNames()
    XCTAssertEqual(names, ["Alpha"])
  }

  func testOutputLimitRejectsPartialCatalog() async throws {
    let fixture = try executable(
      "/usr/bin/awk 'BEGIN { for (i=0; i<30000; i++) print \"Alpha\"; }'")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    await assertFailure(
      .outputLimitExceeded,
      catalog: ShortcutsCatalog(executableURL: fixture, maximumOutputByteCount: 64))
  }

  func testExactOutputLimitIsAccepted() async throws {
    let fixture = try executable("printf 'abc\\n'")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    let names = try await ShortcutsCatalog(executableURL: fixture, maximumOutputByteCount: 4)
      .shortcutNames()
    XCTAssertEqual(names, ["abc"])
  }

  func testInvalidUTF8IsNotAnEmptySuccess() async throws {
    let fixture = try executable("printf '\\377'")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    await assertFailure(.invalidOutput, catalog: ShortcutsCatalog(executableURL: fixture))
  }

  func testDeadlineStopsHangingListing() async throws {
    let fixture = try executable("exec /bin/sleep 5")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    let start = ContinuousClock.now
    await assertFailure(
      .timedOut, catalog: ShortcutsCatalog(executableURL: fixture, timeout: .milliseconds(50)))
    XCTAssertLessThan(start.duration(to: .now), .seconds(3))
  }

  func testDeadlineStillAppliesAfterStdoutCloses() async throws {
    let fixture = try executable("exec 1>&-\nexec /bin/sleep 5")
    defer { try? FileManager.default.removeItem(at: fixture.deletingLastPathComponent()) }
    await assertFailure(
      .timedOut, catalog: ShortcutsCatalog(executableURL: fixture, timeout: .milliseconds(50)))
  }

  func testCancellationStopsAndReapsAChildIgnoringTerminate() async throws {
    let directory = try makeTemporaryDirectory()
    defer { try? FileManager.default.removeItem(at: directory) }
    let ready = directory.appendingPathComponent("ready")
    // The fixture writes only its own process identity, then replaces itself.
    let fixture = try executable(
      "trap '' TERM\necho $$ > '\(ready.path)'\nexec /bin/sleep 5", in: directory)
    let catalog = ShortcutsCatalog(executableURL: fixture, timeout: .seconds(5))
    let task = Task { try await catalog.shortcutNames() }
    defer { task.cancel() }
    let deadline = ContinuousClock.now.advanced(by: .seconds(3))
    while !FileManager.default.fileExists(atPath: ready.path), ContinuousClock.now < deadline {
      try await Task.sleep(for: .milliseconds(10))
    }
    let pid = try XCTUnwrap(
      Int32(
        String(contentsOf: ready, encoding: .utf8).trimmingCharacters(in: .whitespacesAndNewlines)))
    task.cancel()
    do {
      _ = try await task.value
      XCTFail("Cancelled listing must not succeed")
    } catch is CancellationError {
      XCTAssertEqual(Darwin.kill(pid, 0), -1)
      XCTAssertEqual(errno, ESRCH)
    }
  }

  func testCancellationBeforeLaunchDoesNotStartProcess() throws {
    let process = ShortcutsCatalogProcess()
    process.cancel()
    XCTAssertThrowsError(
      try process.run(
        executableURL: URL(fileURLWithPath: "/not-used"), timeout: .seconds(1),
        maximumOutputByteCount: 64)
    ) {
      XCTAssertTrue($0 is CancellationError)
    }
  }

  private func executable(_ body: String, in existingDirectory: URL? = nil) throws -> URL {
    let directory = try existingDirectory ?? makeTemporaryDirectory()
    let file = directory.appendingPathComponent("catalog-fixture")
    try ("#!/bin/sh\n" + body + "\n").write(to: file, atomically: true, encoding: .utf8)
    try FileManager.default.setAttributes([.posixPermissions: 0o700], ofItemAtPath: file.path)
    return file
  }

  private func assertFailure(
    _ expected: ShortcutsCatalogError, catalog: ShortcutsCatalog, file: StaticString = #filePath,
    line: UInt = #line
  ) async {
    do {
      _ = try await catalog.shortcutNames()
      XCTFail("Expected listing failure", file: file, line: line)
    } catch {
      XCTAssertEqual(error as? ShortcutsCatalogError, expected, file: file, line: line)
    }
  }
}

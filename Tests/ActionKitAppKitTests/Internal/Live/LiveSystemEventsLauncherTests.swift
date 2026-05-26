import XCTest

@testable import ActionKitAppKit

final class LiveSystemEventsLauncherTests: XCTestCase {
  func testEnsureRunningReturnsTrueWhenAlreadyRunning() async {
    let probe = SystemEventsLaunchProbe(isRunning: true)
    let launcher = LiveSystemEventsLauncher(
      isRunning: { await probe.isRunning },
      launch: { await probe.launch() },
      sleep: { _ in }
    )

    let result = await launcher.ensureRunning()

    XCTAssertTrue(result)
    let launchCount = await probe.currentLaunchCount()
    XCTAssertEqual(launchCount, 0)
  }

  func testEnsureRunningLaunchesAndWaitsUntilRunning() async {
    let probe = SystemEventsLaunchProbe(isRunning: false)
    let launcher = LiveSystemEventsLauncher(
      isRunning: { await probe.isRunning },
      launch: { await probe.launch() },
      sleep: { _ in }
    )

    let result = await launcher.ensureRunning()

    XCTAssertTrue(result)
    let launchCount = await probe.currentLaunchCount()
    XCTAssertEqual(launchCount, 1)
  }

  func testEnsureRunningPollsUntilSystemEventsBecomesRunning() async {
    let probe = PollingSystemEventsLaunchProbe(runningOnCheck: 3)
    let launcher = LiveSystemEventsLauncher(
      isRunning: { await probe.checkIsRunning() },
      launch: { await probe.launch() },
      sleep: { _ in await probe.sleep() }
    )

    let result = await launcher.ensureRunning()

    XCTAssertTrue(result)
    let launchCount = await probe.currentLaunchCount()
    XCTAssertEqual(launchCount, 1)
    let sleepCount = await probe.currentSleepCount()
    XCTAssertEqual(sleepCount, 1)
  }

  func testConcurrentEnsureRunningSharesLaunchTask() async {
    let probe = SuspendedSystemEventsLaunchProbe()
    let launcher = LiveSystemEventsLauncher(
      isRunning: { await probe.checkIsRunning() },
      launch: { await probe.launch() },
      sleep: { _ in }
    )

    async let first = launcher.ensureRunning()
    async let second = launcher.ensureRunning()

    await probe.waitForLaunch()
    await probe.waitForRunningChecks(count: 2)
    let inFlightLaunchCount = await probe.currentLaunchCount()
    XCTAssertEqual(inFlightLaunchCount, 1)

    await probe.finishLaunch()
    let results = await [first, second]

    XCTAssertEqual(results, [true, true])
    let finalLaunchCount = await probe.currentLaunchCount()
    XCTAssertEqual(finalLaunchCount, 1)
  }

  func testEnsureRunningReturnsFalseWhenLaunchDoesNotMakeSystemEventsRunning() async {
    let probe = SystemEventsLaunchProbe(isRunning: false, launchMakesRunning: false)
    let launcher = LiveSystemEventsLauncher(
      isRunning: { await probe.isRunning },
      launch: { await probe.launch() },
      sleep: { _ in }
    )

    let result = await launcher.ensureRunning()

    XCTAssertFalse(result)
    let launchCount = await probe.currentLaunchCount()
    XCTAssertEqual(launchCount, 1)
  }

  func testEnsureRunningRetriesAfterFailedLaunch() async {
    let probe = SystemEventsLaunchProbe(isRunning: false, launchResults: [false, true])
    let launcher = LiveSystemEventsLauncher(
      isRunning: { await probe.isRunning },
      launch: { await probe.launch() },
      sleep: { _ in }
    )

    let first = await launcher.ensureRunning()
    let second = await launcher.ensureRunning()

    XCTAssertFalse(first)
    XCTAssertTrue(second)
    let launchCount = await probe.currentLaunchCount()
    XCTAssertEqual(launchCount, 2)
  }
}

private actor SystemEventsLaunchProbe {
  private var running: Bool
  private var launchResults: [Bool]
  private(set) var launchCount = 0

  init(isRunning: Bool, launchMakesRunning: Bool = true) {
    running = isRunning
    self.launchResults = [launchMakesRunning]
  }

  init(isRunning: Bool, launchResults: [Bool]) {
    running = isRunning
    self.launchResults = launchResults
  }

  var isRunning: Bool {
    running
  }

  func launch() {
    launchCount += 1
    let launchMakesRunning =
      launchResults.isEmpty
      ? false
      : launchResults.removeFirst()
    if launchMakesRunning {
      running = true
    }
  }

  func currentLaunchCount() -> Int {
    launchCount
  }
}

private actor PollingSystemEventsLaunchProbe {
  private let runningOnCheck: Int
  private var runningCheckCount = 0
  private var launchCount = 0
  private var sleepCount = 0

  init(runningOnCheck: Int) {
    self.runningOnCheck = runningOnCheck
  }

  func checkIsRunning() -> Bool {
    runningCheckCount += 1
    return runningCheckCount >= runningOnCheck
  }

  func launch() {
    launchCount += 1
  }

  func sleep() {
    sleepCount += 1
  }

  func currentLaunchCount() -> Int {
    launchCount
  }

  func currentSleepCount() -> Int {
    sleepCount
  }
}

private actor SuspendedSystemEventsLaunchProbe {
  private var running = false
  private var runningCheckCount = 0
  private var launchCount = 0
  private var launchContinuation: CheckedContinuation<Void, Never>?
  private var runningCheckWaiters: [(count: Int, continuation: CheckedContinuation<Void, Never>)] =
    []
  private var launchWaiters: [CheckedContinuation<Void, Never>] = []

  func checkIsRunning() -> Bool {
    runningCheckCount += 1
    resumeSatisfiedRunningCheckWaiters()
    return running
  }

  func launch() async {
    launchCount += 1
    launchWaiters.forEach { $0.resume() }
    launchWaiters.removeAll()
    await withCheckedContinuation { continuation in
      launchContinuation = continuation
    }
    running = true
  }

  func waitForLaunch() async {
    if launchCount > 0 {
      return
    }

    await withCheckedContinuation { continuation in
      launchWaiters.append(continuation)
    }
  }

  func waitForRunningChecks(count: Int) async {
    if runningCheckCount >= count {
      return
    }

    await withCheckedContinuation { continuation in
      runningCheckWaiters.append((count: count, continuation: continuation))
    }
  }

  func finishLaunch() {
    launchContinuation?.resume()
    launchContinuation = nil
  }

  func currentLaunchCount() -> Int {
    launchCount
  }

  private func resumeSatisfiedRunningCheckWaiters() {
    let satisfied = runningCheckWaiters.filter { $0.count <= runningCheckCount }
    runningCheckWaiters.removeAll { $0.count <= runningCheckCount }
    satisfied.forEach { $0.continuation.resume() }
  }
}

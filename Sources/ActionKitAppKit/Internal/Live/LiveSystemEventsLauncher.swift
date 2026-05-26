import AppKit
import Foundation

struct LiveSystemEventsLauncher: SystemEventsLaunching {
  private let coordinator: SystemEventsLaunchCoordinator

  init(
    isRunning: @escaping @Sendable () async -> Bool = {
      await MainActor.run {
        !NSRunningApplication.runningApplications(
          withBundleIdentifier: SystemEventsLaunchCoordinator.bundleIdentifier
        ).isEmpty
      }
    },
    launch: @escaping @Sendable () async -> Void = {
      await SystemEventsLaunchCoordinator.launchSystemEvents()
    },
    sleep: @escaping @Sendable (UInt64) async -> Void = { nanoseconds in
      try? await Task.sleep(nanoseconds: nanoseconds)
    }
  ) {
    coordinator = SystemEventsLaunchCoordinator(
      isRunning: isRunning,
      launch: launch,
      sleep: sleep
    )
  }

  func ensureRunning() async -> Bool {
    await coordinator.ensureRunning()
  }

  actor SystemEventsLaunchCoordinator {
    private static let appURL = URL(
      fileURLWithPath: "/System/Library/CoreServices/System Events.app")
    fileprivate static let bundleIdentifier = "com.apple.systemevents"
    private static let maxRunningChecks = 20
    private static let runningCheckInterval: UInt64 = 50_000_000

    private let isRunning: @Sendable () async -> Bool
    private let launch: @Sendable () async -> Void
    private let sleep: @Sendable (UInt64) async -> Void
    private var launchTask: Task<Bool, Never>?

    init(
      isRunning: @escaping @Sendable () async -> Bool,
      launch: @escaping @Sendable () async -> Void,
      sleep: @escaping @Sendable (UInt64) async -> Void
    ) {
      self.isRunning = isRunning
      self.launch = launch
      self.sleep = sleep
    }

    func ensureRunning() async -> Bool {
      if await isRunning() {
        return true
      }

      if let existingTask = launchTask {
        return await existingTask.value
      }

      let task = Task { [isRunning, launch, sleep] in
        await launch()
        for _ in 0..<Self.maxRunningChecks {
          if await isRunning() {
            return true
          }
          await sleep(Self.runningCheckInterval)
        }
        return await isRunning()
      }

      launchTask = task
      let result = await task.value
      launchTask = nil
      return result
    }

    @MainActor
    fileprivate static func launchSystemEvents() async {
      let configuration = NSWorkspace.OpenConfiguration()
      configuration.activates = false

      await withCheckedContinuation { continuation in
        NSWorkspace.shared.openApplication(at: Self.appURL, configuration: configuration) { _, _ in
          continuation.resume()
        }
      }
    }
  }
}

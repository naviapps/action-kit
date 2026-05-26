import Foundation

struct LiveScreenCaptureProcessRunner: ScreenCaptureProcessRunning {
  private let executableURL: URL

  init(executableURL: URL = URL(fileURLWithPath: "/usr/sbin/screencapture")) {
    self.executableURL = executableURL
  }

  func run(arguments: [String]) async -> Result<Void, ScreenCaptureProcessFailure> {
    await Task.detached(priority: .userInitiated) {
      runSynchronously(arguments: arguments)
    }.value
  }

  private func runSynchronously(arguments: [String]) -> Result<Void, ScreenCaptureProcessFailure> {
    let process = Process()
    process.executableURL = executableURL
    process.arguments = arguments

    do {
      try process.run()
      process.waitUntilExit()
      if process.terminationStatus != 0 {
        return .failure(.init(terminationStatus: process.terminationStatus))
      }
      return .success(())
    } catch {
      return .failure(.init(terminationStatus: nil))
    }
  }
}

import AppKit

struct LiveFrontmostApplicationController: FrontmostApplicationControlling {
  private let hideFrontmost: @MainActor @Sendable () -> FrontmostApplicationControlResult
  private let terminateFrontmost: @MainActor @Sendable () -> FrontmostApplicationControlResult

  init(
    hideFrontmost: @escaping @MainActor @Sendable () -> FrontmostApplicationControlResult = {
      Self.controlFrontmostApplication { $0.hide() }
    },
    terminateFrontmost: @escaping @MainActor @Sendable () -> FrontmostApplicationControlResult = {
      Self.controlFrontmostApplication { $0.terminate() }
    }
  ) {
    self.hideFrontmost = hideFrontmost
    self.terminateFrontmost = terminateFrontmost
  }

  func hideFrontmostApplication() async -> FrontmostApplicationControlResult {
    await MainActor.run {
      hideFrontmost()
    }
  }

  func terminateFrontmostApplication() async -> FrontmostApplicationControlResult {
    await MainActor.run {
      terminateFrontmost()
    }
  }

  @MainActor
  private static func controlFrontmostApplication(
    _ command: (NSRunningApplication) -> Bool
  ) -> FrontmostApplicationControlResult {
    guard let app = NSWorkspace.shared.frontmostApplication else {
      return .noFrontmostApplication
    }
    return command(app) ? .success : .failed
  }
}

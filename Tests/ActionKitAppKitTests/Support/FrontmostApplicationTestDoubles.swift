@testable import ActionKitAppKit

struct TestFrontmostApplicationController: FrontmostApplicationControlling {
  let hideResult: FrontmostApplicationControlResult
  let terminateResult: FrontmostApplicationControlResult

  init(
    hideResult: FrontmostApplicationControlResult = .success,
    terminateResult: FrontmostApplicationControlResult = .success
  ) {
    self.hideResult = hideResult
    self.terminateResult = terminateResult
  }

  func hideFrontmostApplication() async -> FrontmostApplicationControlResult {
    hideResult
  }

  func terminateFrontmostApplication() async -> FrontmostApplicationControlResult {
    terminateResult
  }
}

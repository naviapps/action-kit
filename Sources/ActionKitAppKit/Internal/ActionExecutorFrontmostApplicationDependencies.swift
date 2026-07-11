package enum FrontmostApplicationControlResult: Sendable, Equatable {
  case success
  case noFrontmostApplication
  case failed
}

package protocol FrontmostApplicationControlling: Sendable {
  func hideFrontmostApplication() async -> FrontmostApplicationControlResult
  func terminateFrontmostApplication() async -> FrontmostApplicationControlResult
}

import XCTest

@testable import ActionKitAppKit

final class LiveWorkspaceTests: XCTestCase {
  func testURLForApplicationNamedFindsApplicationBundleInSearchDirectory() async throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let appURL = try createApplicationBundle(named: "Example.app", in: searchDirectory)
    let workspace = LiveWorkspace(applicationSearchDirectories: [searchDirectory.path])

    let resolvedURL = await workspace.urlForApplication(named: "Example")

    XCTAssertEqual(standardizedPath(resolvedURL), standardizedPath(appURL))
  }

  func testURLForApplicationNamedUsesFirstMatchingSearchDirectory() async throws {
    let firstSearchDirectory = try makeTemporaryDirectory()
    let secondSearchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: firstSearchDirectory)
      try? FileManager.default.removeItem(at: secondSearchDirectory)
    }
    let firstAppURL = try createApplicationBundle(named: "Example.app", in: firstSearchDirectory)
    _ = try createApplicationBundle(named: "Example.app", in: secondSearchDirectory)
    let workspace = LiveWorkspace(
      applicationSearchDirectories: [
        firstSearchDirectory.path,
        secondSearchDirectory.path,
      ])

    let resolvedURL = await workspace.urlForApplication(named: "Example")

    XCTAssertEqual(standardizedPath(resolvedURL), standardizedPath(firstAppURL))
  }

  func testURLForApplicationNamedExpandsTildeSearchDirectory() async throws {
    let directoryName = ".action-kit-\(UUID().uuidString)"
    let searchDirectory = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(directoryName)
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let appURL = try createApplicationBundle(named: "Example.app", in: searchDirectory)
    let workspace = LiveWorkspace(applicationSearchDirectories: ["~/\(directoryName)"])

    let resolvedURL = await workspace.urlForApplication(named: "Example")

    XCTAssertEqual(standardizedPath(resolvedURL), standardizedPath(appURL))
  }

  func testURLForApplicationNamedReturnsNilWhenApplicationBundleIsMissing() async throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let workspace = LiveWorkspace(applicationSearchDirectories: [searchDirectory.path])

    let resolvedURL = await workspace.urlForApplication(named: "Missing")

    XCTAssertNil(resolvedURL)
  }

  func testURLForApplicationNamedRejectsNonDirectoryApplicationPath() async throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let fileURL = searchDirectory.appendingPathComponent("Example.app")
    XCTAssertTrue(FileManager.default.createFile(atPath: fileURL.path, contents: Data()))
    let workspace = LiveWorkspace(applicationSearchDirectories: [searchDirectory.path])

    let resolvedURL = await workspace.urlForApplication(named: "Example")

    XCTAssertNil(resolvedURL)
  }

  func testURLForApplicationNamedAcceptsCaseInsensitiveAppSuffix() async throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let appURL = try createApplicationBundle(named: "Example.APP", in: searchDirectory)
    let workspace = LiveWorkspace(applicationSearchDirectories: [searchDirectory.path])

    let resolvedURL = await workspace.urlForApplication(named: "Example.APP")

    XCTAssertEqual(standardizedPath(resolvedURL), standardizedPath(appURL))
  }

  func testURLForApplicationNamedRejectsPathLikeNames() async throws {
    let parentDirectory = try makeTemporaryDirectory()
    let searchDirectory = parentDirectory.appendingPathComponent("Search")
    let escapedAppURL = parentDirectory.appendingPathComponent("Escaped.app")
    defer {
      try? FileManager.default.removeItem(at: parentDirectory)
    }
    try FileManager.default.createDirectory(at: searchDirectory, withIntermediateDirectories: true)
    try createDirectory(at: escapedAppURL)
    let workspace = LiveWorkspace(applicationSearchDirectories: [searchDirectory.path])

    let resolvedURL = await workspace.urlForApplication(named: "../Escaped")

    XCTAssertNil(resolvedURL)
  }

  func testURLForApplicationNamedRejectsTildePrefixedNames() async throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    _ = try createApplicationBundle(named: "~Example.app", in: searchDirectory)
    let workspace = LiveWorkspace(applicationSearchDirectories: [searchDirectory.path])

    let resolvedURL = await workspace.urlForApplication(named: "~Example")

    XCTAssertNil(resolvedURL)
  }

  func testURLForApplicationNamedRejectsEmptyAndUnnormalizedNames() async throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    _ = try createApplicationBundle(named: "Example.app", in: searchDirectory)
    let workspace = LiveWorkspace(applicationSearchDirectories: [searchDirectory.path])

    for name in ["", " Example "] {
      let resolvedURL = await workspace.urlForApplication(named: name)

      XCTAssertNil(resolvedURL)
    }
  }
}

private func createApplicationBundle(named name: String, in directory: URL) throws -> URL {
  let url = directory.appendingPathComponent(name)
  try createDirectory(at: url)
  return url
}

private func createDirectory(at url: URL) throws {
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
}

private func standardizedPath(_ url: URL?) -> String? {
  url?.standardized.path
}

import XCTest

import ActionKitAppKit

final class ApplicationBundleResolverTests: XCTestCase {
  func testURLForApplicationNamedFindsApplicationBundleInSearchDirectory() throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let appURL = try createApplicationBundle(named: "Example.app", in: searchDirectory)
    let resolver = ApplicationBundleResolver(searchDirectories: [searchDirectory.path])

    let resolvedURL = resolver.urlForApplication(named: "Example")

    XCTAssertEqual(standardizedPath(resolvedURL), standardizedPath(appURL))
  }

  func testURLForApplicationNamedUsesFirstMatchingSearchDirectory() throws {
    let firstSearchDirectory = try makeTemporaryDirectory()
    let secondSearchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: firstSearchDirectory)
      try? FileManager.default.removeItem(at: secondSearchDirectory)
    }
    let firstAppURL = try createApplicationBundle(named: "Example.app", in: firstSearchDirectory)
    _ = try createApplicationBundle(named: "Example.app", in: secondSearchDirectory)
    let resolver = ApplicationBundleResolver(
      searchDirectories: [
        firstSearchDirectory.path,
        secondSearchDirectory.path,
      ])

    let resolvedURL = resolver.urlForApplication(named: "Example")

    XCTAssertEqual(standardizedPath(resolvedURL), standardizedPath(firstAppURL))
  }

  func testURLForApplicationNamedExpandsTildeSearchDirectory() throws {
    let directoryName = ".action-kit-\(UUID().uuidString)"
    let searchDirectory = FileManager.default.homeDirectoryForCurrentUser
      .appendingPathComponent(directoryName)
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let appURL = try createApplicationBundle(named: "Example.app", in: searchDirectory)
    let resolver = ApplicationBundleResolver(searchDirectories: ["~/\(directoryName)"])

    let resolvedURL = resolver.urlForApplication(named: "Example")

    XCTAssertEqual(standardizedPath(resolvedURL), standardizedPath(appURL))
  }

  func testURLForApplicationNamedReturnsNilWhenApplicationBundleIsMissing() throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let resolver = ApplicationBundleResolver(searchDirectories: [searchDirectory.path])

    let resolvedURL = resolver.urlForApplication(named: "Missing")

    XCTAssertNil(resolvedURL)
  }

  func testURLForApplicationNamedRejectsNonDirectoryApplicationPath() throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let fileURL = searchDirectory.appendingPathComponent("Example.app")
    XCTAssertTrue(FileManager.default.createFile(atPath: fileURL.path, contents: Data()))
    let resolver = ApplicationBundleResolver(searchDirectories: [searchDirectory.path])

    let resolvedURL = resolver.urlForApplication(named: "Example")

    XCTAssertNil(resolvedURL)
  }

  func testURLForApplicationNamedAcceptsCaseInsensitiveAppSuffix() throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    let appURL = try createApplicationBundle(named: "Example.APP", in: searchDirectory)
    let resolver = ApplicationBundleResolver(searchDirectories: [searchDirectory.path])

    let resolvedURL = resolver.urlForApplication(named: "Example.APP")

    XCTAssertEqual(standardizedPath(resolvedURL), standardizedPath(appURL))
  }

  func testURLForApplicationNamedRejectsPathLikeNames() throws {
    let parentDirectory = try makeTemporaryDirectory()
    let searchDirectory = parentDirectory.appendingPathComponent("Search")
    let escapedAppURL = parentDirectory.appendingPathComponent("Escaped.app")
    defer {
      try? FileManager.default.removeItem(at: parentDirectory)
    }
    try FileManager.default.createDirectory(at: searchDirectory, withIntermediateDirectories: true)
    try createDirectory(at: escapedAppURL)
    let resolver = ApplicationBundleResolver(searchDirectories: [searchDirectory.path])

    let resolvedURL = resolver.urlForApplication(named: "../Escaped")

    XCTAssertNil(resolvedURL)
  }

  func testURLForApplicationNamedRejectsTildePrefixedNames() throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    _ = try createApplicationBundle(named: "~Example.app", in: searchDirectory)
    let resolver = ApplicationBundleResolver(searchDirectories: [searchDirectory.path])

    let resolvedURL = resolver.urlForApplication(named: "~Example")

    XCTAssertNil(resolvedURL)
  }

  func testURLForApplicationNamedRejectsEmptyAndUnnormalizedNames() throws {
    let searchDirectory = try makeTemporaryDirectory()
    defer {
      try? FileManager.default.removeItem(at: searchDirectory)
    }
    _ = try createApplicationBundle(named: "Example.app", in: searchDirectory)
    let resolver = ApplicationBundleResolver(searchDirectories: [searchDirectory.path])

    for name in ["", " Example "] {
      let resolvedURL = resolver.urlForApplication(named: name)

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

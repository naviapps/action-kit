import Foundation
import XCTest

final class ActionKitSourceBoundaryTests: XCTestCase {
  func testExecutionResultInitializersStayOutOfInternalPublicSurface() throws {
    let resultsRoot = Self.repositoryRoot().appendingPathComponent("Sources/ActionKit/Results")
    let attemptSource = try String(
      contentsOf: resultsRoot.appendingPathComponent("ActionAttempt.swift"),
      encoding: .utf8
    )
    let outcomeSource = try String(
      contentsOf: resultsRoot.appendingPathComponent("ActionOutcome.swift"),
      encoding: .utf8
    )

    XCTAssertFalse(
      containsPublicInitializer(withParameterLabels: ["requiredPermissions"], in: attemptSource),
      "ActionAttempt is an executor observation record; hosts should inspect and decode it, not fabricate execution attempts."
    )
    XCTAssertFalse(
      containsPublicInitializer(withParameterLabels: ["step"], in: attemptSource),
      "ActionAttempt is an executor observation record; ActionStep construction stays package-owned."
    )
    XCTAssertFalse(
      containsPublicInitializer(withParameterLabels: ["attempts"], in: outcomeSource),
      "ActionOutcome should be produced by ActionExecutor or decoded from payloads, not constructed as host input."
    )
  }

  func testActionErrorRawInitializerStaysOutOfPublicSurface() throws {
    let source = try String(
      contentsOf: Self.repositoryRoot()
        .appendingPathComponent("Sources/ActionKit/Results/ActionError.swift"),
      encoding: .utf8
    )

    XCTAssertFalse(
      containsPublicInitializer(withParameterLabels: ["code"], in: source),
      "ActionError should expose canonical factories, not a raw initializer that can create invalid code-specific payloads."
    )
  }

  func testActionKitCoreDoesNotImportWindowKit() throws {
    let sourceFiles = try swiftSourceFiles(under: "Sources/ActionKit")

    XCTAssertFalse(sourceFiles.isEmpty)
    for sourceFile in sourceFiles {
      XCTAssertFalse(
        sourceFile.source.containsImport("WindowKit"),
        "\(sourceFile.relativePath) imports WindowKit; keep WindowKit mapping in ActionKitAppKit."
      )
    }
  }

  func testInternalSourceTreesDoNotExposePublicDeclarations() throws {
    for relativeRoot in ["Sources/ActionKit/Planning", "Sources/ActionKitAppKit/Internal"] {
      let sourceFiles = try swiftSourceFiles(under: relativeRoot)

      XCTAssertFalse(sourceFiles.isEmpty, "\(relativeRoot) should contain internal source files.")
      for sourceFile in sourceFiles {
        XCTAssertFalse(
          containsPublicOrOpenDeclaration(in: sourceFile.source),
          "\(sourceFile.relativePath) exposes public API from an internal source tree."
        )
      }
    }
  }

  func testActionExecutorDependencyInjectionStaysOutOfPublicSurface() throws {
    let source = try readRepositoryFile("Sources/ActionKitAppKit/Execution/ActionExecutor.swift")

    XCTAssertFalse(
      containsPublicProperty(named: "configuration", in: source),
      "Executor configuration should be supplied at construction, not exposed as mutable host API."
    )
    XCTAssertFalse(
      containsPublicProperty(named: "dependencies", in: source),
      "Live executor dependencies are package internals for test seams and platform adapters."
    )
    XCTAssertFalse(
      containsPublicInitializer(
        withParameterLabels: ["configuration", "dependencies"], in: source),
      "Dependency injection is for package tests; host apps should use init(configuration:)."
    )
  }

  func testActionPreflightPlanningSeamsStayNarrow() throws {
    let preflightSource = try readRepositoryFile(
      "Sources/ActionKit/Preflight/ActionPreflight.swift"
    )
    XCTAssertFalse(
      containsPublicStaticFunction(named: "plan", in: preflightSource),
      "Hosts should use permissions(forKind:) and permissionHints(forKind:), not sample plans."
    )
  }

  func testInternalActionInputNormalizationStaysOutOfPublicSurface() throws {
    let source = try String(
      contentsOf: Self.repositoryRoot()
        .appendingPathComponent("Sources/ActionKit/Actions/ActionInput.swift"),
      encoding: .utf8
    )

    XCTAssertFalse(
      containsPublicProperty(named: "normalized", in: source),
      "ActionInput normalization is an internal validation detail exposed through creation and Codable boundaries."
    )
    XCTAssertFalse(
      containsPublicStaticFunction(named: "normalizedString", in: source),
      "ActionInput string normalization is an internal validation detail, not a host-facing utility API."
    )
  }

  private func readRepositoryFile(_ relativePath: String) throws -> String {
    try String(
      contentsOf: Self.repositoryRoot().appendingPathComponent(relativePath),
      encoding: .utf8
    )
  }

  private func swiftSourceFiles(under relativeRoot: String) throws -> [SourceFile] {
    let root = Self.repositoryRoot().appendingPathComponent(relativeRoot)
    let urls =
      FileManager.default
      .enumerator(at: root, includingPropertiesForKeys: nil)?
      .compactMap { $0 as? URL }
      .filter { $0.pathExtension == "swift" } ?? []

    return
      try urls

      .map { url in
        SourceFile(
          relativePath: url.path.replacingOccurrences(
            of: Self.repositoryRoot().path + "/",
            with: ""
          ),
          source: try String(contentsOf: url, encoding: .utf8)
        )
      }
      .sorted { $0.relativePath < $1.relativePath }
  }

  private func containsPublicOrOpenDeclaration(in source: String) -> Bool {
    source.split(separator: "\n").contains { line in
      line.range(
        of:
          #"^\s*(?:@[\w.]+(?:\([^)]*\))?\s*)*(?:public|open)\s+(?:actor|class|enum|extension|final\s+class|func|import|init|let|protocol|struct|subscript|typealias|var)\b"#,
        options: .regularExpression
      ) != nil
    }
  }

  private func containsPublicInitializer(
    withParameterLabels labels: [String],
    in source: String
  ) -> Bool {
    let labelPattern =
      labels
      .map { #"\b"# + NSRegularExpression.escapedPattern(for: $0) + #"\s*:"# }
      .joined(separator: #"[^{}]*"#)
    let pattern =
      #"(?ms)^\s*(?:@[\w.]+(?:\([^)]*\))?\s*)*public\s+(?:convenience\s+)?init\b[^{}]*"#
      + labelPattern

    return source.range(of: pattern, options: .regularExpression) != nil
  }

  private func containsPublicProperty(named name: String, in source: String) -> Bool {
    let pattern =
      #"^\s*(?:@[\w.]+(?:\([^)]*\))?\s*)*public\s+(?:static\s+)?(?:let|var)\s+"#
      + NSRegularExpression.escapedPattern(for: name)
      + #"\b"#
    return source.split(separator: "\n").contains { line in
      line.range(of: pattern, options: .regularExpression) != nil
    }
  }

  private func containsPublicStaticFunction(named name: String, in source: String) -> Bool {
    let pattern =
      #"^\s*(?:@[\w.]+(?:\([^)]*\))?\s*)*public\s+static\s+func\s+"#
      + NSRegularExpression.escapedPattern(for: name)
      + #"\s*\("#
    return source.split(separator: "\n").contains { line in
      line.range(of: pattern, options: .regularExpression) != nil
    }
  }

  private static func repositoryRoot() -> URL {
    URL(fileURLWithPath: #filePath)
      .deletingLastPathComponent()
      .deletingLastPathComponent()
      .deletingLastPathComponent()
  }
}

private struct SourceFile {
  let relativePath: String
  let source: String
}

private extension String {
  func containsImport(_ moduleName: String) -> Bool {
    range(
      of: #"(?m)^\s*import\s+"# + NSRegularExpression.escapedPattern(for: moduleName) + #"\b"#,
      options: .regularExpression
    ) != nil
  }
}

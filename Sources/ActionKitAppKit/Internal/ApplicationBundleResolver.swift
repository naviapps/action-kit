import Foundation

package struct ApplicationBundleResolver: Sendable {
  private let searchDirectories: [String]

  package init(searchDirectories: [String]) {
    self.searchDirectories = searchDirectories
  }

  package func urlForApplication(named name: String) -> URL? {
    guard isPlainApplicationName(name) else { return nil }

    let fileName = applicationBundleFileName(for: name)
    for directory in searchDirectories {
      let expanded = (directory as NSString).expandingTildeInPath
      let url = URL(fileURLWithPath: expanded).appendingPathComponent(fileName)
      if isApplicationBundle(at: url) {
        return url
      }
    }
    return nil
  }

  private func isPlainApplicationName(_ name: String) -> Bool {
    let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
    return !trimmed.isEmpty && trimmed == name && !name.hasPrefix("~") && !name.contains("/")
  }

  private func applicationBundleFileName(for name: String) -> String {
    let url = URL(fileURLWithPath: name)
    guard url.pathExtension.lowercased() != "app" else {
      return name
    }
    return "\(name).app"
  }

  private func isApplicationBundle(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return url.pathExtension.lowercased() == "app"
      && FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory)
      && isDirectory.boolValue
  }
}

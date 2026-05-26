import Foundation

func makeTemporaryDirectory() throws -> URL {
  let url = makeTemporaryURL()
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}

func makeTemporaryApplicationBundleDirectory() throws -> URL {
  let url = makeTemporaryURL(pathExtension: "app")
  try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  return url
}

func makeTemporaryFile() throws -> URL {
  let url = makeTemporaryURL()
  try Data().write(to: url, options: .withoutOverwriting)
  return url
}

private func makeTemporaryURL(pathExtension: String? = nil) -> URL {
  var url = FileManager.default.temporaryDirectory
    .appendingPathComponent(UUID().uuidString)
  if let pathExtension {
    url.appendPathExtension(pathExtension)
  }
  return url
}

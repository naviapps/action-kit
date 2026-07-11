// swift-tools-version: 6.0
import PackageDescription

func naviappsPackage(
  _ repository: String,
  localPathEnvironmentKey: String,
  from version: Version
) -> Package.Dependency {
  if let localPath = Context.environment[localPathEnvironmentKey], !localPath.isEmpty {
    return .package(path: localPath)
  }

  return .package(url: "https://github.com/naviapps/\(repository).git", from: version)
}

let package = Package(
  name: "ActionKit",
  platforms: [.macOS(.v14)],
  products: [
    .library(
      name: "ActionKit",
      targets: ["ActionKit"]
    ),
    .library(
      name: "ActionKitAppKit",
      targets: ["ActionKitAppKit"]
    ),
  ],
  dependencies: [
    naviappsPackage(
      "window-kit",
      localPathEnvironmentKey: "WINDOW_KIT_PATH",
      from: "2.0.0"
    )
  ],
  targets: [
    .target(
      name: "ActionKit"
    ),
    .target(
      name: "ActionKitAppKit",
      dependencies: [
        "ActionKit",
        .product(name: "WindowKit", package: "window-kit"),
        .product(name: "WindowKitAppKit", package: "window-kit"),
      ]
    ),
    .testTarget(
      name: "ActionKitTests",
      dependencies: [
        "ActionKit"
      ]
    ),
    .testTarget(
      name: "ActionKitAppKitTests",
      dependencies: [
        "ActionKit",
        "ActionKitAppKit",
        .product(name: "WindowKit", package: "window-kit"),
        .product(name: "WindowKitAppKit", package: "window-kit"),
      ]
    ),
  ]
)

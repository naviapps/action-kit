// swift-tools-version: 5.10
import PackageDescription

let package = Package(
  name: "ActionKit",
  platforms: [.macOS(.v13)],
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
    .package(url: "https://github.com/naviapps/window-kit", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "ActionKit",
      dependencies: [
        .product(name: "WindowKit", package: "window-kit")
      ],
      path: "Sources/ActionKit"
    ),
    .target(
      name: "ActionKitAppKit",
      dependencies: [
        "ActionKit",
        .product(name: "WindowKitAppKit", package: "window-kit"),
      ],
      path: "Sources/ActionKitAppKit"
    ),
    .testTarget(
      name: "ActionKitTests",
      dependencies: [
        "ActionKit",
        .product(name: "WindowKit", package: "window-kit"),
      ],
      path: "Tests/ActionKitTests"
    ),
    .testTarget(
      name: "ActionKitAppKitTests",
      dependencies: [
        "ActionKit",
        "ActionKitAppKit",
        .product(name: "WindowKit", package: "window-kit"),
        .product(name: "WindowKitAppKit", package: "window-kit"),
      ],
      path: "Tests/ActionKitAppKitTests"
    ),
  ]
)

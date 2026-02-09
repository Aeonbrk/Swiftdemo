// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

private let swiftDataLinkerSettings: [LinkerSetting] = [
  .linkedFramework("SwiftData")
]

let package = Package(
  name: "Core",
  platforms: [
    .macOS(.v14),
    .iOS(.v17),
    .visionOS(.v1),
  ],
  products: [
    .library(
      name: "Core",
      targets: ["Core"]
    )
  ],
  targets: [
    .target(
      name: "Core",
      linkerSettings: swiftDataLinkerSettings
    ),
    .testTarget(
      name: "CoreTests",
      dependencies: ["Core"],
      linkerSettings: swiftDataLinkerSettings
    ),
  ]
)

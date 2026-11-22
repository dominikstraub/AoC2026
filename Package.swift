// swift-tools-version: 6.4
import PackageDescription

let dependencies: [Target.Dependency] = [
  .product(name: "Algorithms", package: "swift-algorithms"),
  .product(name: "Collections", package: "swift-collections"),
  .product(name: "ArgumentParser", package: "swift-argument-parser"),
]

let package = Package(
  name: "AdventOfCode",
  platforms: [.macOS(.v27)],
  dependencies: [
    .package(
      url: "https://github.com/apple/swift-algorithms.git",
      .upToNextMajor(from: "1.2.1")
    ),
    .package(
      url: "https://github.com/apple/swift-collections.git",
      .upToNextMajor(from: "1.7.6")
    ),
    .package(
      url: "https://github.com/apple/swift-argument-parser.git",
      .upToNextMajor(from: "1.8.2")
    ),
  ],
  targets: [
    .executableTarget(
      name: "AdventOfCode",
      dependencies: dependencies,
      resources: [.copy("Data")]
    ),
    .testTarget(
      name: "AdventOfCodeTests",
      dependencies: ["AdventOfCode"] + dependencies
    ),
  ],
  swiftLanguageModes: [.v6]
)

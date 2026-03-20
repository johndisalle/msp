// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FaithForgeShared",
    platforms: [
        .iOS(.v18),
        .watchOS(.v11),
    ],
    products: [
        .library(
            name: "FaithForgeShared",
            targets: ["FaithForgeShared"]
        ),
    ],
    targets: [
        .target(
            name: "FaithForgeShared",
            path: "Sources/FaithForgeShared"
        ),
        .testTarget(
            name: "FaithForgeSharedTests",
            dependencies: ["FaithForgeShared"],
            path: "Tests/FaithForgeSharedTests"
        ),
    ]
)

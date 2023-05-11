// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "paste-for-gmail",
    platforms: [
        .macOS(.v12),
    ],
    targets: [
        .executableTarget(
            name: "paste-for-gmail"),
    ]
)

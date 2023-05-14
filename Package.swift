// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "web-paste",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "WebPaste",
            dependencies: ["SwiftSoup"]),
        .testTarget(
            name: "WebPasteTests",
            dependencies: ["WebPaste"]),
    ]
)

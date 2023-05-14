// swift-tools-version: 5.8

import PackageDescription

let package = Package(
    name: "paste-for-gmail",
    platforms: [
        .macOS(.v13),
    ],
    dependencies: [
        .package(url: "https://github.com/scinfu/SwiftSoup.git", from: "2.6.0"),
    ],
    targets: [
        .executableTarget(
            name: "PasteForGmail",
            dependencies: ["SwiftSoup"]),
        .testTarget(
            name: "PasteForGmailTests",
            dependencies: ["PasteForGmail"]),
    ]
)

// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EmojiPicker",
    defaultLocalization: "en",
    platforms: [.macOS(.v13), .iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EmojiPicker",
            targets: ["EmojiPicker"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/tyiu/EmojiKit", .upToNextMajor(from: "0.2.0")),
        .package(url: "https://github.com/tyiu/swift-trie", .upToNextMajor(from: "0.1.2"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "EmojiPicker",
            dependencies: [
                .product(name: "EmojiKit", package: "EmojiKit"),
                .product(name: "SwiftTrie", package: "swift-trie")
            ],
            resources: [
                .process("Resources")
            ]
        )
    ]
)

// swift-tools-version:5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "EmojiPicker",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15),
        .macOS(.v12),
        .tvOS(.v15),
        .watchOS(.v8),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "EmojiPicker",
            targets: [
                "EmojiPicker",
            ]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(
            url: "https://github.com/apple/swift-docc-plugin",
            "1.0.0" ..< "2.0.0"
        )
    ],
    targets: [
        // Targets are the basic building blocks of a package.
        // A target can define a module or a test suite.
        //
        // Targets can depend on other targets in this package,
        // and on products in packages which this package depends on.
        .target(
            name: "EmojiPicker",
            dependencies: [
            ],
            path: "EmojiPicker/",
            exclude: [
            ],
            resources: [
                .process("Resources"),
                .process("Icons.xcassets")
            ]
        ),
        .testTarget(
            name: "EmojiPickerTests",
            dependencies: [
                "EmojiPicker",
            ],
            path: "Tests/EmojiPicker/",
            exclude: [
                "Resources/README.md",
                "Toolbox/README.md",
            ],
            resources: [
                .process("Resources"),
            ]
        ),
    ]
)

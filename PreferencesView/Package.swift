// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PreferencesView",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15),
    ],
    products: [
        .library(
            name: "PreferencesView",
            targets: ["PreferencesView"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/MarioIannotta/SwizzleSwift", branch: "master"),
    ],
    targets: [
        .target(
            name: "PreferencesView",
            dependencies: [.product(name: "SwizzleSwift", package: "SwizzleSwift")]
        ),
    ]
)

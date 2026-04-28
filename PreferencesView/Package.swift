// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "PreferencesView",
    platforms: [
        .iOS(.v16),
        .tvOS(.v16),
    ],
    products: [
        .library(
            name: "PreferencesView",
            targets: ["PreferencesView"]
        ),
    ],
    targets: [
        .target(
            name: "PreferencesView",
        ),
    ]
)

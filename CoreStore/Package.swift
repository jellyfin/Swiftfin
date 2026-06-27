// swift-tools-version:5.9
//
// Vendored local copy of CoreStore (https://github.com/JohnEstropia/CoreStore), pinned at 9.3.0.
//
// Why this exists: Swift 6.4 / Xcode 27 makes CoreStore's `cs_sync` overloads ambiguous
// ("Ambiguous use of 'cs_sync'"). The redundant `throws(any Swift.Error)` overload in
// Sources/DispatchQueue+CoreStore.swift has been removed here so the project builds on Xcode 27.
// The test target and demo/docs have been dropped from this vendored copy; only the library
// is needed. Upstream officially targets Xcode 26.3.
//

import PackageDescription

let package = Package(
    name: "CoreStore",
    platforms: [
        .macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9),
    ],
    products: [
        .library(name: "CoreStore", targets: ["CoreStore"]),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CoreStore",
            dependencies: [],
            path: "Sources"
        ),
    ],
    swiftLanguageVersions: [.v5]
)

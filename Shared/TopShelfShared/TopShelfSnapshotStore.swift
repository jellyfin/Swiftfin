//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum TopShelfSnapshotStore {

    private static let appGroupInfoKey = "TopShelfAppGroupIdentifier"
    private static let snapshotFilename = "TopShelfSnapshot.json"
    private static let snapshotSubdirectory = "Library/Caches"
    private static let imageCacheSubdirectory = "TopShelfImages"
    #if targetEnvironment(simulator)
    private static let simulatorSnapshotSubdirectory = "TopShelfSnapshots"
    #endif

    private static var appGroupIdentifier: String? {
        guard let value = Bundle.main.object(forInfoDictionaryKey: appGroupInfoKey) as? String,
              !value.isEmpty
        else { return nil }

        return value
    }

    private static var containerURL: URL? {
        guard let appGroupIdentifier else { return nil }

        return FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupIdentifier
        )
    }

    #if targetEnvironment(simulator)
    private static var simulatorSharedResourcesURL: URL? {
        guard let path = ProcessInfo.processInfo.environment["SIMULATOR_SHARED_RESOURCES_DIRECTORY"],
              !path.isEmpty
        else { return nil }

        return URL(fileURLWithPath: path, isDirectory: true)
    }

    private static var simulatorFallbackSnapshotURL: URL? {
        guard let simulatorSharedResourcesURL else { return nil }

        let identifier = appGroupIdentifier ?? Bundle.main.bundleIdentifier ?? "TopShelf"

        return simulatorSharedResourcesURL
            .appendingPathComponent(simulatorSnapshotSubdirectory, isDirectory: true)
            .appendingPathComponent(identifier, isDirectory: true)
            .appendingPathComponent(snapshotFilename)
    }
    #endif

    private static var snapshotURL: URL? {
        if let containerURL {
            return containerURL
                .appendingPathComponent(snapshotSubdirectory, isDirectory: true)
                .appendingPathComponent(snapshotFilename)
        }

        #if targetEnvironment(simulator)
        return simulatorFallbackSnapshotURL
        #else
        return nil
        #endif
    }

    private static var snapshotDirectoryURL: URL? {
        snapshotURL?.deletingLastPathComponent()
    }

    private static var imageCacheDirectoryURL: URL? {
        snapshotDirectoryURL?
            .appendingPathComponent(imageCacheSubdirectory, isDirectory: true)
    }

    private static var legacySnapshotURL: URL? {
        guard let containerURL else { return nil }

        return containerURL.appendingPathComponent(snapshotFilename)
    }

    static func load() throws -> TopShelfSnapshot? {
        guard let snapshotURL else { return nil }

        let fileManager = FileManager.default
        let resolvedSnapshotURL: URL? = if fileManager.fileExists(atPath: snapshotURL.path) {
            snapshotURL
        } else if let legacySnapshotURL, fileManager.fileExists(atPath: legacySnapshotURL.path) {
            legacySnapshotURL
        } else {
            nil
        }

        guard let resolvedSnapshotURL else {
            #if DEBUG
            NSLog(
                "TopShelf: no snapshot found, app group %@, container %@, fallback %@",
                appGroupIdentifier ?? "<missing-app-group>",
                containerURL?.path ?? "<missing-container>",
                {
                    #if targetEnvironment(simulator)
                    simulatorFallbackSnapshotURL?.path ?? "<missing-fallback>"
                    #else
                    "<not-applicable>"
                    #endif
                }()
            )
            #endif
            return nil
        }

        let data = try Data(contentsOf: resolvedSnapshotURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        #if DEBUG
        NSLog("TopShelf: loaded snapshot from %@", resolvedSnapshotURL.path)
        #endif

        return try decoder.decode(TopShelfSnapshot.self, from: data)
    }

    static func save(_ snapshot: TopShelfSnapshot) throws {
        guard let snapshotURL else {
            #if DEBUG
            NSLog(
                "TopShelf: unable to resolve snapshot URL, app group %@, container %@",
                appGroupIdentifier ?? "<missing-app-group>",
                containerURL?.path ?? "<missing-container>"
            )
            #endif
            return
        }

        try FileManager.default.createDirectory(
            at: snapshotURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601

        let data = try encoder.encode(snapshot)
        try data.write(to: snapshotURL, options: .atomic)

        #if DEBUG
        NSLog(
            "TopShelf: saved snapshot with %ld items to %@",
            snapshot.items.count,
            snapshotURL.path
        )
        #endif
    }

    static func cacheImageData(
        _ data: Data,
        for itemID: String,
        pathExtension: String = "jpg"
    ) throws -> URL {
        guard let imageCacheDirectoryURL else {
            throw CocoaError(.fileNoSuchFile)
        }

        try FileManager.default.createDirectory(
            at: imageCacheDirectoryURL,
            withIntermediateDirectories: true
        )

        try removeCachedImageVariants(for: itemID)

        let imageURL = imageCacheDirectoryURL
            .appendingPathComponent(itemID)
            .appendingPathExtension(sanitizedPathExtension(pathExtension) ?? "jpg")

        try data.write(to: imageURL, options: .atomic)

        #if DEBUG
        NSLog("TopShelf: cached image for %@ at %@", itemID, imageURL.path)
        #endif

        return imageURL
    }

    static func pruneCachedImages(keeping itemIDs: some Sequence<String>) throws {
        guard let imageCacheDirectoryURL else { return }

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: imageCacheDirectoryURL.path) else { return }

        let keepSet = Set(itemIDs)
        let imageURLs = try fileManager.contentsOfDirectory(
            at: imageCacheDirectoryURL,
            includingPropertiesForKeys: nil
        )

        for imageURL in imageURLs where !keepSet.contains(imageURL.deletingPathExtension().lastPathComponent) {
            try fileManager.removeItem(at: imageURL)
        }
    }

    static func clear() throws {
        let fileManager = FileManager.default

        if let snapshotURL, fileManager.fileExists(atPath: snapshotURL.path) {
            try fileManager.removeItem(at: snapshotURL)
        }

        if let legacySnapshotURL, fileManager.fileExists(atPath: legacySnapshotURL.path) {
            try fileManager.removeItem(at: legacySnapshotURL)
        }

        if let imageCacheDirectoryURL, fileManager.fileExists(atPath: imageCacheDirectoryURL.path) {
            try fileManager.removeItem(at: imageCacheDirectoryURL)
        }

        #if DEBUG
        NSLog("TopShelf: cleared snapshot")
        #endif
    }

    private static func removeCachedImageVariants(for itemID: String) throws {
        guard let imageCacheDirectoryURL else { return }

        let fileManager = FileManager.default

        guard fileManager.fileExists(atPath: imageCacheDirectoryURL.path) else { return }

        let imageURLs = try fileManager.contentsOfDirectory(
            at: imageCacheDirectoryURL,
            includingPropertiesForKeys: nil
        )

        for imageURL in imageURLs where imageURL.deletingPathExtension().lastPathComponent == itemID {
            try fileManager.removeItem(at: imageURL)
        }
    }

    private static func sanitizedPathExtension(_ pathExtension: String) -> String? {
        let value = pathExtension
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !value.isEmpty else { return nil }
        guard value.range(of: "^[a-z0-9]+$", options: .regularExpression) != nil else { return nil }

        return value
    }
}

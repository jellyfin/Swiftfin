//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import Logging

enum TopShelfSnapshotStore {

    private static let logger = Logger(label: "org.jellyfin.swiftfin")
    private static let appGroupInfoKey = "TopShelfAppGroupIdentifier"
    private static let snapshotFilename = "TopShelfSnapshot.json"
    private static let snapshotSubdirectory = "Library/Caches"
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

    private static var simulatorFallbackDirectoryURL: URL? {
        guard let simulatorSharedResourcesURL else { return nil }

        let identifier = appGroupIdentifier ?? Bundle.main.bundleIdentifier ?? "TopShelf"

        return simulatorSharedResourcesURL
            .appendingPathComponent(simulatorSnapshotSubdirectory, isDirectory: true)
            .appendingPathComponent(identifier, isDirectory: true)
    }
    #endif

    static var storageDirectoryURL: URL? {
        if let containerURL {
            return containerURL.appendingPathComponent(snapshotSubdirectory, isDirectory: true)
        }

        #if targetEnvironment(simulator)
        return simulatorFallbackDirectoryURL
        #else
        return nil
        #endif
    }

    private static var snapshotURL: URL? {
        storageDirectoryURL?
            .appendingPathComponent(snapshotFilename, isDirectory: false)
    }

    private static var legacySnapshotURL: URL? {
        guard let containerURL else { return nil }

        return containerURL.appendingPathComponent(snapshotFilename, isDirectory: false)
    }

    static func load() throws -> TopShelfSnapshot? {
        let fileManager = FileManager.default

        let resolvedSnapshotURL: URL? = if let snapshotURL, fileManager.fileExists(atPath: snapshotURL.path) {
            snapshotURL
        } else if let legacySnapshotURL, fileManager.fileExists(atPath: legacySnapshotURL.path) {
            legacySnapshotURL
        } else {
            nil
        }

        guard let resolvedSnapshotURL else {
            logger.debug("No top shelf snapshot available")
            return nil
        }

        let data = try Data(contentsOf: resolvedSnapshotURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        logger.debug("Loaded top shelf snapshot from \(resolvedSnapshotURL.path)")

        return try decoder.decode(TopShelfSnapshot.self, from: data)
    }

    static func save(_ snapshot: TopShelfSnapshot) throws {
        guard let snapshotURL else {
            logger.warning("Unable to resolve a storage location for the top shelf snapshot")
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

        logger.debug("Saved top shelf snapshot with \(snapshot.items.count) items")
    }

    static func clear() throws {
        let fileManager = FileManager.default

        if let snapshotURL, fileManager.fileExists(atPath: snapshotURL.path) {
            try fileManager.removeItem(at: snapshotURL)
        }

        if let legacySnapshotURL, fileManager.fileExists(atPath: legacySnapshotURL.path) {
            try fileManager.removeItem(at: legacySnapshotURL)
        }

        logger.debug("Cleared top shelf snapshot")
    }
}

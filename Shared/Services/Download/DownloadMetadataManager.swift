//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Logging

final class DownloadMetadataManager: DownloadMetadataManaging {

    private let logger = Logger.swiftfin()
    private let fileService: DownloadFileServicing

    init(fileService: DownloadFileServicing) {
        self.fileService = fileService
    }

    // MARK: - Public Interface

    func readMetadata(itemId: String) -> DownloadMetadata? {
        let downloadPath = URL.downloads.appendingPathComponent(itemId)
        let metadataFile = downloadPath.appendingPathComponent("metadata.json")

        logger.debug("Looking for metadata file at: \(metadataFile.path)")

        guard FileManager.default.fileExists(atPath: metadataFile.path),
              let data = FileManager.default.contents(atPath: metadataFile.path)
        else {
            logger.debug("Metadata file not found or empty for itemId: \(itemId)")
            return nil
        }

        do {
            let metadata = try JSONDecoder().decode(DownloadMetadata.self, from: data)
            logger.debug("Successfully decoded metadata for itemId: \(itemId), versions count: \(metadata.versions.count)")
            return metadata
        } catch {
            logger.warning("Failed to decode metadata for item \(itemId): \(error)")
            return nil
        }
    }

    func writeMetadata(for task: DownloadTask) throws {
        guard let downloadFolder = task.item.downloadFolder else { return }

        // Ensure root folder exists before saving
        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)

        // Save the merged metadata.json containing item and versions
        try saveMetadata(for: task, at: downloadFolder)

        // Cleanup: remove legacy Metadata folder if present
        let legacyMetadataFolder = downloadFolder.appendingPathComponent("Metadata")
        var isDir: ObjCBool = false
        if FileManager.default.fileExists(atPath: legacyMetadataFolder.path, isDirectory: &isDir), isDir.boolValue {
            do {
                try FileManager.default.removeItem(at: legacyMetadataFolder)
            } catch {
                logger.warning("Failed to remove legacy Metadata folder: \(error.localizedDescription)")
            }
        }

        logger.trace("Saved merged metadata for: \(task.item.displayTitle)")
    }

    func getDownloadedVersions(for itemId: String) -> [VersionInfo] {
        readMetadata(itemId: itemId)?.versions ?? []
    }

    func parseDownloadItem(with id: String) -> DownloadTask? {
        let root = URL.downloads.appendingPathComponent(id)
        let mergedMetadataFile = root.appendingPathComponent("metadata.json")

        let jsonDecoder = JSONDecoder()

        // Prefer merged metadata.json with embedded item
        if let data = FileManager.default.contents(atPath: mergedMetadataFile.path),
           let meta = try? jsonDecoder.decode(DownloadMetadata.self, from: data),
           let offlineItem = meta.item
        {
            let task = DownloadTask(item: offlineItem)
            task.state = .complete
            return task
        }

        // Backward-compatibility: try old Metadata/Item.json
        let legacyItemFile = root.appendingPathComponent("Metadata").appendingPathComponent("Item.json")
        if let itemData = FileManager.default.contents(atPath: legacyItemFile.path),
           let offlineItem = try? jsonDecoder.decode(BaseItemDto.self, from: itemData)
        {
            let task = DownloadTask(item: offlineItem)
            task.state = .complete
            return task
        }

        return nil
    }

    // MARK: - Debug Helpers

    func debugListDownloadedItems() {
        logger.debug("=== DEBUG: Listing all downloaded items ===")

        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            logger.debug("Found \(downloadContents.count) folders in downloads directory")

            for itemId in downloadContents {
                logger.debug("Checking item folder: \(itemId)")

                let downloadPath = URL.downloads.appendingPathComponent(itemId)
                var isDirectory: ObjCBool = false

                if FileManager.default.fileExists(atPath: downloadPath.path, isDirectory: &isDirectory) && isDirectory.boolValue {
                    logger.debug("  - Is valid directory")

                    let metadataFile = downloadPath.appendingPathComponent("metadata.json")
                    if FileManager.default.fileExists(atPath: metadataFile.path) {
                        logger.debug("  - metadata.json exists")

                        if let metadata = readMetadata(itemId: itemId) {
                            logger.debug("  - Metadata loaded successfully: \(metadata.displayTitle)")
                            logger.debug("  - Versions count: \(metadata.versions.count)")

                            for (index, version) in metadata.versions.enumerated() {
                                logger
                                    .debug(
                                        "    Version \(index): versionId=\(version.versionId), mediaSourceId=\(version.mediaSourceId ?? "nil")"
                                    )
                            }
                        } else {
                            logger.debug("  - Failed to load metadata")
                        }
                    } else {
                        logger.debug("  - metadata.json does not exist")
                    }
                } else {
                    logger.debug("  - Not a valid directory")
                }
            }
        } catch {
            logger.error("Error listing downloaded items: \(error)")
        }

        logger.debug("=== END DEBUG ===")
    }

    func debugCheckSpecificVersion(itemId: String, mediaSourceId: String?) {
        logger.debug("=== DEBUG: Checking specific version ===")
        logger.debug("Looking for itemId: \(itemId), mediaSourceId: \(mediaSourceId ?? "nil")")

        let hasItem = fileService.isItemDownloaded(itemId: itemId)
        let hasMedia = fileService.hasMediaFile(for: itemId, mediaSourceId: mediaSourceId)
        let versions = getDownloadedVersions(for: itemId)

        logger.debug("Has item directory: \(hasItem)")
        logger.debug("Has media file: \(hasMedia)")
        logger.debug("Versions count: \(versions.count)")

        // Normalize the mediaSourceId - nil should be treated as itemId
        let targetMediaSourceId = mediaSourceId ?? itemId
        logger.debug("Target mediaSourceId (normalized): \(targetMediaSourceId)")

        let hasMetadataVersion = versions.contains { version in
            let versionMediaSourceId = version.mediaSourceId ?? itemId
            logger.debug("Comparing target '\(targetMediaSourceId)' with version '\(versionMediaSourceId)'")
            return versionMediaSourceId == targetMediaSourceId
        }

        logger.debug("Has metadata version: \(hasMetadataVersion)")
        let result = hasItem && hasMedia && hasMetadataVersion
        logger.debug("Final result: \(result)")
        logger.debug("=== END SPECIFIC VERSION DEBUG ===")
    }

    // MARK: - Private Helpers

    private func saveMetadata(for task: DownloadTask, at folder: URL) throws {
        let metadataFile = folder.appendingPathComponent("metadata.json")

        // Load existing metadata if it exists
        var downloadMetadata: DownloadMetadata

        // Ensure folder exists before writing metadata
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        if FileManager.default.fileExists(atPath: metadataFile.path),
           let existingData = FileManager.default.contents(atPath: metadataFile.path)
        {
            // Try to decode existing metadata
            do {
                downloadMetadata = try JSONDecoder().decode(DownloadMetadata.self, from: existingData)
            } catch {
                // If decoding fails, create new metadata (might be old format)
                logger.warning("Failed to decode existing metadata.json, creating new: \(error)")
                downloadMetadata = DownloadMetadata(
                    itemId: task.item.id ?? "",
                    itemType: task.item.type?.rawValue,
                    displayTitle: task.item.displayTitle
                )
            }
        } else {
            // Create new metadata
            downloadMetadata = DownloadMetadata(
                itemId: task.item.id ?? "",
                itemType: task.item.type?.rawValue,
                displayTitle: task.item.displayTitle
            )
        }

        // Ensure embedded item is present/updated
        downloadMetadata.item = task.item

        // Create version entry - use mediaSourceId as the unique identifier
        let uniqueVersionId = task.mediaSourceId ?? task.item.id ?? "default"
        let versionInfo = VersionInfo(
            versionId: uniqueVersionId,
            container: task.container,
            isStatic: task.isStatic,
            mediaSourceId: task.mediaSourceId,
            downloadDate: ISO8601DateFormatter().string(from: Date()),
            taskId: task.taskID.uuidString
        )

        // Remove existing version with same mediaSourceId if it exists
        downloadMetadata.versions.removeAll { version in
            let existingMediaSourceId = version.mediaSourceId
            let currentMediaSourceId = task.mediaSourceId

            // Compare mediaSourceIds, treating nil as equivalent to item.id
            let normalizedExisting = existingMediaSourceId ?? task.item.id
            let normalizedCurrent = currentMediaSourceId ?? task.item.id

            return normalizedExisting == normalizedCurrent
        }

        // Add new version
        downloadMetadata.versions.append(versionInfo)

        // Save metadata using JSONEncoder for consistent formatting
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(downloadMetadata)
        try jsonData.write(to: metadataFile)

        logger.trace("Updated metadata.json for: \(task.item.displayTitle) with \(downloadMetadata.versions.count) versions")
    }
}

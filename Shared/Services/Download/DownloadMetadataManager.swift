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

        // First try to read from the main metadata file
        if FileManager.default.fileExists(atPath: metadataFile.path),
           let data = FileManager.default.contents(atPath: metadataFile.path)
        {
            do {
                let metadata = try JSONDecoder().decode(DownloadMetadata.self, from: data)
                logger.debug("Successfully decoded metadata for itemId: \(itemId), versions count: \(metadata.versions.count)")
                return metadata
            } catch {
                logger.warning("Failed to decode metadata for item \(itemId): \(error)")
            }
        }

        // If not found, check if this might be a series folder and aggregate metadata from seasons
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: downloadPath.path)
            let seasonFolders = contents.filter { $0.hasPrefix("Season-") }

            if !seasonFolders.isEmpty {
                // This is a series folder, aggregate metadata from season folders
                var allVersions: [VersionInfo] = []
                var seriesItem: BaseItemDto?

                for seasonFolder in seasonFolders.sorted() {
                    let seasonPath = downloadPath.appendingPathComponent(seasonFolder)
                    let seasonMetadataFile = seasonPath.appendingPathComponent("metadata.json")

                    if let seasonData = FileManager.default.contents(atPath: seasonMetadataFile.path),
                       let seasonMeta = try? JSONDecoder().decode(DownloadMetadata.self, from: seasonData)
                    {
                        allVersions.append(contentsOf: seasonMeta.versions)
                        if seriesItem == nil, let item = seasonMeta.item {
                            seriesItem = item
                        }
                    }
                }

                if !allVersions.isEmpty {
                    let aggregatedMetadata = DownloadMetadata(
                        itemId: itemId,
                        itemType: "Series",
                        displayTitle: seriesItem?.seriesName ?? "Unknown Series",
                        item: seriesItem,
                        versions: allVersions
                    )
                    logger.debug("Aggregated metadata for series: \(itemId), total versions: \(allVersions.count)")
                    return aggregatedMetadata
                }
            }
        } catch {
            logger.debug("Could not read series contents: \(error)")
        }

        logger.debug("Metadata file not found or empty for itemId: \(itemId)")
        return nil
    }

    func writeMetadata(for task: DownloadTask) throws {
        guard let downloadFolder = task.item.downloadFolder else { return }

        // Ensure root folder exists before saving
        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)

        if task.item.type == .episode {
            // For episodes, write metadata at both series and season levels
            try writeSeriesMetadata(for: task, at: downloadFolder)
            try writeSeasonMetadata(for: task, at: downloadFolder)
        } else {
            // For movies, write metadata at item level (existing behavior)
            try saveMetadata(for: task, at: downloadFolder)
        }

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

        logger.trace("Saved metadata for: \(task.item.displayTitle)")
    }

    func getDownloadedVersions(for itemId: String) -> [VersionInfo] {
        readMetadata(itemId: itemId)?.versions ?? []
    }

    func parseDownloadItem(with id: String) -> DownloadTask? {
        let root = URL.downloads.appendingPathComponent(id)
        let mergedMetadataFile = root.appendingPathComponent("metadata.json")

        let jsonDecoder = JSONDecoder()

        // First, try merged metadata.json with embedded item (new format)
        if let data = FileManager.default.contents(atPath: mergedMetadataFile.path),
           let meta = try? jsonDecoder.decode(DownloadMetadata.self, from: data),
           let offlineItem = meta.item
        {
            let task = DownloadTask(item: offlineItem)
            return task
        }

        // Check if this is a series folder with season subfolders
        do {
            let contents = try FileManager.default.contentsOfDirectory(atPath: root.path)
            let seasonFolders = contents.filter { $0.hasPrefix("Season-") }

            if !seasonFolders.isEmpty {
                // This is a series folder, look for episodes in season folders
                for seasonFolder in seasonFolders {
                    let seasonPath = root.appendingPathComponent(seasonFolder)
                    let seasonMetadataFile = seasonPath.appendingPathComponent("metadata.json")

                    if let seasonData = FileManager.default.contents(atPath: seasonMetadataFile.path),
                       let seasonMeta = try? jsonDecoder.decode(DownloadMetadata.self, from: seasonData),
                       let episodeItem = seasonMeta.item,
                       episodeItem.type == .episode
                    {
                        // Return the first episode found as a representative
                        let task = DownloadTask(item: episodeItem)
                        return task
                    }
                }
            }
        } catch {
            logger.debug("Could not read contents of download folder: \(error)")
        }

        // Backward-compatibility: try old Metadata/Item.json
        let legacyItemFile = root.appendingPathComponent("Metadata").appendingPathComponent("Item.json")
        if let itemData = FileManager.default.contents(atPath: legacyItemFile.path),
           let offlineItem = try? jsonDecoder.decode(BaseItemDto.self, from: itemData)
        {
            let task = DownloadTask(item: offlineItem)
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

    private func writeSeriesMetadata(for task: DownloadTask, at seriesFolder: URL) throws {
        guard task.item.type == .episode else { return }

        let metadataFile = seriesFolder.appendingPathComponent("metadata.json")
        var seriesMetadata: DownloadMetadata

        // Create or update series metadata
        if FileManager.default.fileExists(atPath: metadataFile.path),
           let existingData = FileManager.default.contents(atPath: metadataFile.path),
           let existing = try? JSONDecoder().decode(DownloadMetadata.self, from: existingData)
        {
            seriesMetadata = existing
        } else {
            // Create new series metadata using series information
            let seriesId = task.item.seriesID ?? ""
            let seriesName = task.item.seriesName ?? task.item.displayTitle
            seriesMetadata = DownloadMetadata(
                itemId: seriesId,
                itemType: "Series",
                displayTitle: seriesName
            )
        }

        // Save series metadata
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(seriesMetadata)
        try jsonData.write(to: metadataFile)

        logger.trace("Updated series metadata for: \(seriesMetadata.displayTitle)")
    }

    private func writeSeasonMetadata(for task: DownloadTask, at seriesFolder: URL) throws {
        guard task.item.type == .episode,
              let season = task.season else { return }

        let seasonFolder = seriesFolder.appendingPathComponent("Season-\(String(format: "%02d", season))")
        try FileManager.default.createDirectory(at: seasonFolder, withIntermediateDirectories: true)

        let metadataFile = seasonFolder.appendingPathComponent("metadata.json")
        var seasonMetadata: DownloadMetadata

        // Create or update season metadata
        if FileManager.default.fileExists(atPath: metadataFile.path),
           let existingData = FileManager.default.contents(atPath: metadataFile.path),
           let existing = try? JSONDecoder().decode(DownloadMetadata.self, from: existingData)
        {
            seasonMetadata = existing
        } else {
            // Create new season metadata
            let seasonId = task.item.seasonID ?? ""
            let seasonName = "Season \(season)"
            seasonMetadata = DownloadMetadata(
                itemId: seasonId,
                itemType: "Season",
                displayTitle: seasonName
            )
        }

        // Create version entry for this episode
        let uniqueVersionId = task.mediaSourceId ?? task.item.id ?? "default"
        let episodeId = task.item.id
        let versionInfo = VersionInfo(
            versionId: uniqueVersionId,
            container: task.container,
            isStatic: task.isStatic,
            mediaSourceId: task.mediaSourceId,
            episodeId: episodeId,
            downloadDate: ISO8601DateFormatter().string(from: Date()),
            taskId: task.taskID.uuidString
        )

        // Remove existing version with same mediaSourceId if it exists
        seasonMetadata.versions.removeAll { version in
            let existingMediaSourceId = version.mediaSourceId
            let currentMediaSourceId = task.mediaSourceId

            // Compare mediaSourceIds, treating nil as equivalent to item.id
            let normalizedExisting = existingMediaSourceId ?? task.item.id
            let normalizedCurrent = currentMediaSourceId ?? task.item.id

            return normalizedExisting == normalizedCurrent
        }

        // Add new version
        seasonMetadata.versions.append(versionInfo)

        // Update embedded item with episode info (template for backward compatibility)
        seasonMetadata.item = task.item

        // Ensure per-episode metadata map exists and store this episode's full item metadata
        var episodesMap = seasonMetadata.episodes ?? [:]
        if let episodeKey = episodeId {
            episodesMap[episodeKey] = task.item
        }
        seasonMetadata.episodes = episodesMap

        // Save season metadata
        let encoder = JSONEncoder()
        encoder.outputFormatting = .prettyPrinted
        let jsonData = try encoder.encode(seasonMetadata)
        try jsonData.write(to: metadataFile)

        logger.trace("Updated season metadata for: \(seasonMetadata.displayTitle) with \(seasonMetadata.versions.count) episodes")
    }

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

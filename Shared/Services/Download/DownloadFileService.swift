//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Files
import Foundation
import JellyfinAPI
import Logging

final class DownloadFileService: DownloadFileServicing {

    private let logger = Logger.swiftfin()

    init() {}

    // MARK: - Directory Management

    func ensureDownloadDirectory() throws {
        try FileManager.default.createDirectory(
            at: URL.downloads,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        logger.trace("Created downloads directory at: \(URL.downloads.path)")
    }

    func clearTmp() {
        do {
            try Folder(path: URL.tmp.path).files.delete()
            logger.trace("Cleared tmp directory")
        } catch {
            logger.error("Unable to clear tmp directory: \(error.localizedDescription)")
        }
    }

    // MARK: - File Operations

    func moveMediaFile(from temp: URL, to destination: URL, for task: DownloadTask, response: URLResponse?) throws {
        guard let downloadFolder = task.item.downloadFolder else {
            throw DownloadTask.DownloadError.notEnoughStorage
        }

        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)

        // Validate media response before moving
        try validateMediaFile(at: temp, response: response)

        let finalDestination = try createMediaFileDestination(
            downloadTask: task,
            response: response,
            downloadFolder: downloadFolder
        )

        try moveFileAtomically(from: temp, to: finalDestination)
        try setFileAttributes(for: finalDestination)

        logger.trace("Moved media file to: \(finalDestination.path)")
    }

    func moveImageFile(
        from temp: URL,
        to destination: URL,
        for task: DownloadTask,
        response: URLResponse?,
        jobType: DownloadJobType,
        context: ImageDownloadContext
    ) throws {
        guard let downloadFolder = task.item.downloadFolder else {
            throw DownloadTask.DownloadError.notEnoughStorage
        }

        let finalDestination = try createImageFileDestination(
            downloadTask: task,
            response: response,
            downloadFolder: downloadFolder,
            jobType: jobType,
            context: context
        )

        try moveFileAtomically(from: temp, to: finalDestination)
        try setFileAttributes(for: finalDestination)

        logger.trace("Moved image file to: \(finalDestination.path)")
    }

    func validateMediaFile(at url: URL, response: URLResponse?) throws {
        // Validate HTTP status code
        if let httpResponse = response as? HTTPURLResponse {
            guard (200 ... 299).contains(httpResponse.statusCode) else {
                logger.error("Invalid HTTP status \(httpResponse.statusCode) for media download")
                throw MediaValidationError.invalidHTTPStatus(httpResponse.statusCode)
            }
        }

        // Basic file size validation - ensure it's not suspiciously small (likely an error page)
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: url.path)
            if let fileSize = fileAttributes[.size] as? Int64, fileSize < 1024 {
                logger.error("Downloaded file is suspiciously small: \(fileSize) bytes")
                throw MediaValidationError.suspiciouslySmallFile(fileSize)
            }
        } catch {
            logger.warning("Unable to validate file size: \(error.localizedDescription)")
        }
    }

    // MARK: - Size Calculations

    func calculateSize(of folder: URL) throws -> Int64 {
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileAllocatedSizeKey]
        let directoryEnumerator = FileManager.default.enumerator(
            at: folder,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )

        var totalSize: Int64 = 0

        if let enumerator = directoryEnumerator as? FileManager.DirectoryEnumerator {
            for case let fileURL as URL in enumerator {
                let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))
                if resourceValues.isRegularFile == true {
                    totalSize += Int64(resourceValues.fileAllocatedSize ?? 0)
                }
            }
        }

        return totalSize
    }

    func getTotalDownloadSize() -> Int64? {
        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            var totalSize: Int64 = 0

            for itemFolder in downloadContents {
                let itemPath = URL.downloads.appendingPathComponent(itemFolder)
                let folderSize = try calculateSize(of: itemPath)
                totalSize += folderSize
            }

            return totalSize
        } catch {
            logger.error("Failed to calculate total download size: \(error.localizedDescription)")
            return nil
        }
    }

    func getDownloadSize(itemId: String) -> Int64? {
        let itemPath = URL.downloads.appendingPathComponent(itemId)

        guard FileManager.default.fileExists(atPath: itemPath.path) else {
            return nil
        }

        do {
            return try calculateSize(of: itemPath)
        } catch {
            logger.error("Failed to calculate download size for item \(itemId): \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Deletion

    func deleteDownloads(for itemId: String) throws -> Bool {
        logger.info("Deleting downloaded media for item: \(itemId)")

        let downloadPath = URL.downloads.appendingPathComponent(itemId)

        guard FileManager.default.fileExists(atPath: downloadPath.path) else {
            logger.warning("No downloaded media found for item: \(itemId)")
            return false
        }

        try FileManager.default.removeItem(at: downloadPath)
        logger.info("Successfully deleted downloaded media for item: \(itemId)")
        return true
    }

    func deleteAllDownloads() throws {
        logger.info("Deleting all downloaded media")

        let downloadFolders = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)

        for folderName in downloadFolders {
            let folderPath = URL.downloads.appendingPathComponent(folderName)
            try FileManager.default.removeItem(at: folderPath)
            logger.trace("Deleted download folder: \(folderName)")
        }

        logger.info("Successfully deleted all downloaded media")
    }

    // MARK: - Status Checks

    func isItemDownloaded(itemId: String) -> Bool {
        let downloadPath = URL.downloads.appendingPathComponent(itemId)
        var isDirectory: ObjCBool = false

        let exists = FileManager.default.fileExists(atPath: downloadPath.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func hasMediaFile(for itemId: String, mediaSourceId: String?) -> Bool {
        let root = URL.downloads.appendingPathComponent(itemId)
        var isDir: ObjCBool = false
        guard FileManager.default.fileExists(atPath: root.path, isDirectory: &isDir), isDir.boolValue else { return false }

        let normalized = mediaSourceId ?? itemId

        // Search recursively up to depth 3 for a media file matching item/version
        // This handles both the old structure (episode folders) and new structure (series folders)
        guard let enumerator = FileManager.default.enumerator(
            at: root,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return false }

        for case let url as URL in enumerator {
            do {
                let values = try url.resourceValues(forKeys: [.isRegularFileKey])
                guard values.isRegularFile == true else { continue }
                let name = url.lastPathComponent

                // Accept either the new naming scheme or legacy "Media.*"
                if name.hasPrefix("Media.") { return true }

                // New naming: [episodeId]-[versionId].ext or [itemId]-[versionId].ext
                if name.hasPrefix(normalized) {
                    return true
                }

                // For backward compatibility, also check if file contains itemId
                if name.contains(itemId) {
                    if mediaSourceId == nil {
                        return true
                    } else if name.contains("-\(normalized)") {
                        return true
                    }
                }
            } catch {
                continue
            }
        }
        return false
    }

    func getDownloadedItemIds() -> [String] {
        do {
            let downloadsURL = URL.downloads

            // Use enumerator for better performance with large numbers of downloads
            guard let enumerator = FileManager.default.enumerator(
                at: downloadsURL,
                includingPropertiesForKeys: [.isDirectoryKey, .nameKey],
                options: [.skipsSubdirectoryDescendants, .skipsHiddenFiles]
            ) else {
                logger.warning("Unable to enumerate downloads directory")
                return []
            }

            var itemIds: [String] = []

            for case let url as URL in enumerator {
                do {
                    let resourceValues = try url.resourceValues(forKeys: [.isDirectoryKey, .nameKey])

                    // Only process directories (downloaded items)
                    guard resourceValues.isDirectory == true,
                          let name = resourceValues.name else { continue }

                    // Verify it's a valid download by checking for metadata.json
                    let metadataPath = url.appendingPathComponent("metadata.json")
                    if FileManager.default.fileExists(atPath: metadataPath.path) {
                        itemIds.append(name)
                    }
                } catch {
                    logger.trace("Error reading directory entry \(url.lastPathComponent): \(error.localizedDescription)")
                }
            }

            return itemIds.sorted() // Return sorted for consistent ordering
        } catch {
            logger.error("Error reading downloads directory: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Disk Space

    func checkAvailableDiskSpace() throws {
        let fileURL = URL.downloads
        let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

        guard let capacity = values.volumeAvailableCapacityForImportantUsage else {
            logger.warning("Unable to determine available disk capacity")
            throw DownloadTask.DownloadError.notEnoughStorage
        }

        // Require at least 100MB free space
        let minimumFreeSpace: Int64 = 100 * 1024 * 1024

        if capacity < minimumFreeSpace {
            logger.error("Insufficient disk space: \(capacity) bytes available, \(minimumFreeSpace) bytes required")
            throw DownloadTask.DownloadError.notEnoughStorage
        }

        logger.trace("Disk space check passed: \(capacity) bytes available")
    }

    // MARK: - Private Helpers

    private func moveFileAtomically(from source: URL, to destination: URL) throws {
        // If a file already exists at destination, replace it atomically
        if FileManager.default.fileExists(atPath: destination.path) {
            let backupURL = destination.appendingPathExtension("backup")

            // Move existing file to backup location first
            try FileManager.default.moveItem(at: destination, to: backupURL)

            do {
                // Move new file to final destination
                try FileManager.default.moveItem(at: source, to: destination)

                // Remove backup if successful
                try? FileManager.default.removeItem(at: backupURL)
            } catch {
                // Restore backup if move failed
                try? FileManager.default.moveItem(at: backupURL, to: destination)
                throw error
            }
        } else {
            // Move file directly if no existing file
            try FileManager.default.moveItem(at: source, to: destination)
        }
    }

    private func setFileAttributes(for url: URL) throws {
        // Set file protection, exclude from backup, and apply security attributes
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true

        // Add file protection for sensitive media content
        do {
            var mutableURL = url
            try mutableURL.setResourceValues(resourceValues)
            try (url as NSURL).setResourceValue(
                FileProtectionType.completeUntilFirstUserAuthentication,
                forKey: .fileProtectionKey
            )
        } catch {
            logger.warning("Failed to set file protection attributes: \(error.localizedDescription)")
        }
    }

    private func createMediaFileDestination(downloadTask: DownloadTask, response: URLResponse?, downloadFolder: URL) throws -> URL {
        // Determine file extension from response
        let fileExtension: String
        if let httpResponse = response as? HTTPURLResponse,
           let contentType = httpResponse.mimeType
        {
            fileExtension = contentType.contains("mp4") ? ".mp4" :
                contentType.contains("mkv") ? ".mkv" :
                ".\(downloadTask.container)"
        } else {
            fileExtension = ".\(downloadTask.container)"
        }

        // Create versioned filename based on file structure specification
        if downloadTask.item.type == .episode,
           let season = downloadTask.season,
           let episodeId = downloadTask.episodeID
        {
            // For episodes: Downloads/[seriesId]/Season-[XX]/[episodeId]-[versionId].ext
            let seasonFolder = downloadFolder.appendingPathComponent("Season-\(String(format: "%02d", season))")
            try FileManager.default.createDirectory(at: seasonFolder, withIntermediateDirectories: true)

            let versionSuffix = downloadTask.versionId.map { "-\($0)" } ?? ""
            let filename = "\(episodeId)\(versionSuffix)\(fileExtension)"
            return seasonFolder.appendingPathComponent(filename)
        } else {
            // For movies: Downloads/[itemId]/[itemId]-[versionId].ext
            let versionSuffix = downloadTask.versionId.map { "-\($0)" } ?? ""
            let filename = "\(downloadTask.item.id!)\(versionSuffix)\(fileExtension)"
            return downloadFolder.appendingPathComponent(filename)
        }
    }

    private func createImageFileDestination(
        downloadTask: DownloadTask,
        response: URLResponse?,
        downloadFolder: URL,
        jobType: DownloadJobType,
        context: ImageDownloadContext
    ) throws -> URL {
        // Determine file extension
        let imageExtension = (response as? HTTPURLResponse)?.mimeSubtype ?? "jpeg"

        // Create context-aware filename
        let imageTypePrefix = jobType == .backdropImage ? "Backdrop" : "Primary"
        let filename: String
        let imagesFolder: URL

        switch context {
        case let .episode(id):
            // Episode images go to season Images folder
            guard let season = downloadTask.season else {
                throw NSError(
                    domain: "DownloadFileService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Season number required for episode images"]
                )
            }
            let seasonFolder = downloadFolder.appendingPathComponent("Season-\(String(format: "%02d", season))")
            imagesFolder = seasonFolder.appendingPathComponent("Images")
            filename = "Episode-\(id)-\(imageTypePrefix).\(imageExtension)"
        case let .season(id):
            // Season images go to season Images folder
            guard let season = downloadTask.season else {
                throw NSError(
                    domain: "DownloadFileService",
                    code: -1,
                    userInfo: [NSLocalizedDescriptionKey: "Season number required for season images"]
                )
            }
            let seasonFolder = downloadFolder.appendingPathComponent("Season-\(String(format: "%02d", season))")
            imagesFolder = seasonFolder.appendingPathComponent("Images")
            filename = "Season-\(id)-\(imageTypePrefix).\(imageExtension)"
        case let .series(id):
            // Series images go to show root Images folder
            imagesFolder = downloadFolder.appendingPathComponent("Images")
            filename = "Series-\(id)-\(imageTypePrefix).\(imageExtension)"
        }

        try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
        return imagesFolder.appendingPathComponent(filename)
    }
}

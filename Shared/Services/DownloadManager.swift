//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Files
import Foundation
import JellyfinAPI
import Logging

extension Container {
    var downloadManager: Factory<DownloadManager> { self { DownloadManager() }.singleton }
}

class DownloadManager: ObservableObject {

    // MARK: - Properties

    private let logger = Logger.swiftfin()

    @Published
    private(set) var downloads: [DownloadTask] = []

    // MARK: - Initialization

    fileprivate init() {
        logger.info("Initializing DownloadManager")
        createDownloadDirectory()
        logger.debug("DownloadManager initialized with \(downloads.count) existing downloads")
    }

    // MARK: - Directory Management

    private func createDownloadDirectory() {
        logger.debug("Creating download directory at: \(URL.downloads)")

        do {
            try FileManager.default.createDirectory(
                at: URL.downloads,
                withIntermediateDirectories: true
            )
            logger.info("Successfully created download directory")
        } catch {
            logger.error("Failed to create download directory: \(error.localizedDescription)")
        }
    }

    func clearTmp() {
        logger.info("Clearing temporary directory")

        do {
            try Folder(path: URL.tmp.path).files.delete()
            logger.info("Successfully cleared tmp directory")
        } catch {
            logger.error("Unable to clear tmp directory: \(error.localizedDescription)")
        }
    }

    func download(task: DownloadTask) {
        logger.info("Starting download for item: \(task.item.displayTitle) (ID: \(task.item.id ?? "unknown"))")
        logger.debug("Current download state: \(task.state)")
        logger.debug("Current downloads count: \(downloads.count)")

        // Log existing downloads for this item
        let existingTasks = downloads.filter { $0.item == task.item }
        if !existingTasks.isEmpty {
            logger.debug("Found \(existingTasks.count) existing tasks for this item:")
            for (index, existingTask) in existingTasks.enumerated() {
                logger.debug("  Task \(index): state=\(existingTask.state)")
            }
        }

        // Remove any existing ready, cancelled or error tasks for this item
        downloads.removeAll {
            guard $0.item == task.item else { return false }
            switch $0.state {
            case .ready, .cancelled, .error:
                logger.debug("Removing existing task in state \($0.state) for item: \(task.item.displayTitle)")
                return true
            default:
                return false
            }
        }

        // Don't add if already downloading or completed
        let shouldSkip = downloads.contains(where: { existingTask in
            guard existingTask.item == task.item else { return false }
            switch existingTask.state {
            case .complete, .downloading:
                return true
            default:
                return false
            }
        })

        if shouldSkip {
            logger.warning("Skipping download - item already downloading or completed: \(task.item.displayTitle)")
            return
        }

        downloads.append(task)
        logger.info("Added download task to queue. Total downloads: \(downloads.count)")

        // Force immediate UI update on main thread for responsive feedback
        DispatchQueue.main.async { [weak self] in
            self?.objectWillChange.send()
        }

        // Enhanced logging for download folder information
        if let downloadFolder = task.item.downloadFolder {
            logger.debug("Download folder for item: \(downloadFolder)")

            // Check if folder already exists
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: downloadFolder.path, isDirectory: &isDirectory)
            logger.debug("Download folder exists: \(exists), isDirectory: \(isDirectory.boolValue)")

            // Special handling for Series downloads
            if task.item.type == .series {
                logger.info("Series download detected. Series downloads require individual episode selection.")
                logger.info("Folder will be created for organizing episodes: \(downloadFolder.path)")

                // Check if the series has any media sources (like trailers)
                if let mediaSources = task.item.mediaSources, !mediaSources.isEmpty {
                    logger.info("Series has \(mediaSources.count) media source(s) - allowing download")
                } else {
                    logger
                        .warning(
                            "Series '\(task.item.displayTitle)' has no direct media sources. Individual episodes should be downloaded instead."
                        )
                    // Still allow the download to proceed as it will create the series folder structure
                }
            }
        } else {
            logger.error("No download folder available for item: \(task.item.displayTitle)")
            logger.error("Item details - ID: \(task.item.id ?? "nil"), Type: \(task.item.type?.rawValue ?? "nil")")

            // Set task to error state and remove from downloads
            task.state = .error(JellyfinAPIError("No download folder available"))
            downloads.removeAll { $0.item == task.item }
            logger.error("Removed failed task from downloads queue")
            return
        }

        task.download()
    }

    // MARK: - Download Management

    func task(for item: BaseItemDto) -> DownloadTask? {
        logger.debug("Looking for download task for item: \(item.displayTitle) (ID: \(item.id ?? "unknown"))")

        // Check currently downloading tasks
        if let currentlyDownloading = downloads.first(where: { $0.item == item }) {
            logger.debug("Found active download task with state: \(currentlyDownloading.state)")
            return currentlyDownloading
        } else {
            logger.debug("No active download task found, checking for completed downloads")

            var isDir: ObjCBool = true
            guard let downloadFolder = item.downloadFolder else {
                logger.debug("No download folder available for item")
                return nil
            }

            guard FileManager.default.fileExists(atPath: downloadFolder.path, isDirectory: &isDir) else {
                logger.debug("Download folder does not exist: \(downloadFolder)")
                return nil
            }

            logger.debug("Download folder exists, parsing download item")
            let parsedTask = parseDownloadItem(with: item.id!)

            if parsedTask != nil {
                logger.debug("Successfully parsed completed download task")
            } else {
                logger.debug("Failed to parse download item - no metadata found")
            }

            return parsedTask
        }
    }

    /// Checks if a specific media source of an item is already downloaded
    func isMediaSourceDownloaded(item: BaseItemDto, mediaSourceId: String) -> Bool {
        logger.debug("Checking if media source \(mediaSourceId) is downloaded for item: \(item.displayTitle)")

        // First, check active downloads that are complete
        if let activeTask = downloads.first(where: { task in
            guard task.item.id == item.id else { return false }
            if case .complete = task.state { return true }
            return false
        }) {
            let hasMediaSource = activeTask.item.mediaSources?.contains { source in
                source.id == mediaSourceId
            } ?? false

            if hasMediaSource {
                logger.debug("Found media source in active completed download")
                return true
            }
        }

        // Then check persisted completed downloads
        if let itemId = item.id,
           let parsedTask = parseDownloadItem(with: itemId)
        {
            let hasMediaSource = parsedTask.item.mediaSources?.contains { source in
                source.id == mediaSourceId
            } ?? false

            if hasMediaSource {
                logger.debug("Found media source in persisted download")
                return true
            }
        }

        logger.debug("Media source not found in downloads")
        return false
    }

    func cancel(task: DownloadTask) {
        logger.info("Cancelling download for item: \(task.item.displayTitle) (ID: \(task.item.id ?? "unknown"))")
        logger.debug("Current task state: \(task.state)")

        guard downloads.contains(where: { $0.item == task.item }) else {
            logger.warning("Attempted to cancel task that is not in downloads array")
            return
        }

        task.cancel()
        logger.debug("Called task.cancel()")

        remove(task: task)
        logger.info("Download cancelled and removed successfully.")
    }

    func remove(task: DownloadTask) {
        logger.info("Removing download task for item: \(task.item.displayTitle) (ID: \(task.item.id ?? "unknown"))")
        logger.debug("Current downloads count before removal: \(downloads.count)")
        logger.debug("Task state at removal: \(task.state)")

        let initialCount = downloads.count
        downloads.removeAll(where: { $0.item == task.item })
        let finalCount = downloads.count

        if initialCount != finalCount {
            logger.info("Successfully removed task. Downloads count: \(initialCount) -> \(finalCount)")
        } else {
            logger.warning("No task was removed - item not found in downloads array")
        }
    }

    // MARK: - Downloaded Items Management

    func downloadedItems() -> [DownloadTask] {
        logger.info("Retrieving all downloaded items")

        // Ensure downloads directory exists
        if !FileManager.default.fileExists(atPath: URL.downloads.path) {
            logger.info("Downloads directory does not exist, creating it")
            createDownloadDirectory()
            return []
        }

        var downloadedTasks: [DownloadTask] = []

        do {
            // Recursively search for all Metadata/Item.json files in the Downloads directory
            downloadedTasks = findDownloadedItems(in: URL.downloads)

            logger.info("Successfully found \(downloadedTasks.count) downloaded items")
            return downloadedTasks
        } catch {
            logger.error("Error retrieving all downloads: \(error.localizedDescription)")
            logger.debug("Download directory path: \(URL.downloads)")
            return []
        }
    }

    private func findDownloadedItems(in directory: URL) -> [DownloadTask] {
        var foundTasks: [DownloadTask] = []

        guard FileManager.default.fileExists(atPath: directory.path) else {
            logger.debug("Directory does not exist: \(directory.path)")
            return foundTasks
        }

        do {
            let contents = try FileManager.default.contentsOfDirectory(
                at: directory,
                includingPropertiesForKeys: [.isDirectoryKey],
                options: []
            )

            for item in contents {
                do {
                    let resourceValues = try item.resourceValues(forKeys: [.isDirectoryKey])

                    if resourceValues.isDirectory == true {
                        // Check if this directory contains a Metadata/Item.json file
                        let metadataPath = item.appendingPathComponent("Metadata").appendingPathComponent("Item.json")

                        if FileManager.default.fileExists(atPath: metadataPath.path) {
                            logger.debug("Found metadata file at: \(metadataPath)")

                            // Try to parse this as a downloaded item
                            if let task = parseDownloadItemFromPath(metadataPath) {
                                foundTasks.append(task)
                                logger.debug("Successfully parsed download task for: \(task.item.displayTitle)")
                            } else {
                                logger.warning("Failed to parse download item from: \(metadataPath)")

                                // Try to read the raw metadata for debugging
                                if let rawData = FileManager.default.contents(atPath: metadataPath.path) {
                                    logger.debug("Raw metadata file size: \(rawData.count) bytes")
                                    if let jsonString = String(data: rawData, encoding: .utf8) {
                                        let preview = String(jsonString.prefix(200))
                                        logger.debug("Metadata preview: \(preview)...")
                                    }
                                }
                            }
                        } else {
                            // Recursively search subdirectories
                            let subTasks = findDownloadedItems(in: item)
                            foundTasks.append(contentsOf: subTasks)
                        }
                    }
                } catch {
                    logger.error("Error processing item \(item.lastPathComponent): \(error)")
                }
            }
        } catch {
            logger.error("Error searching directory \(directory): \(error.localizedDescription)")
        }

        return foundTasks
    }

    // MARK: - Metadata Parsing

    private func parseDownloadItemFromPath(_ metadataPath: URL) -> DownloadTask? {
        logger.debug("Parsing download item from metadata path: \(metadataPath)")

        guard let itemMetadataData = FileManager.default.contents(atPath: metadataPath.path) else {
            logger.debug("No metadata file found at: \(metadataPath)")
            return nil
        }

        logger.debug("Found metadata file, size: \(itemMetadataData.count) bytes")

        let jsonDecoder = JSONDecoder()

        guard let offlineItem = try? jsonDecoder.decode(BaseItemDto.self, from: itemMetadataData) else {
            logger.error("Failed to decode metadata JSON from: \(metadataPath)")
            return nil
        }

        logger.debug("Successfully decoded metadata for item: \(offlineItem.displayTitle)")

        let task = DownloadTask(item: offlineItem)
        task.state = .complete
        logger.debug("Created download task with complete state")

        return task
    }

    private func parseDownloadItem(with id: String) -> DownloadTask? {
        logger.debug("Parsing download item with ID: \(id)")

        let itemMetadataFile = URL.downloads
            .appendingPathComponent(id)
            .appendingPathComponent("Metadata")
            .appendingPathComponent("Item.json")

        return parseDownloadItemFromPath(itemMetadataFile)
    }

    // MARK: - Deletion

    func deleteDownload(task: DownloadTask) {
        logger.info("Deleting downloaded content for item: \(task.item.displayTitle) (ID: \(task.item.id ?? "unknown"))")

        // Remove from active downloads array if present
        downloads.removeAll { $0.item == task.item }
        logger.debug("Removed task from active downloads array")

        // Delete the root folder and all contents
        task.deleteRootFolder()

        // Clean up stored filename from UserDefaults
        if let itemId = task.item.id {
            UserDefaults.standard.removeObject(forKey: "download_\(itemId)_filename")
            logger.debug("Cleaned up UserDefaults entry for item: \(itemId)")
        }

        logger.info("Successfully deleted download for: \(task.item.displayTitle)")
    }

    // MARK: - Media Source Download Status

    /// Checks if a specific media source from an item is already downloaded
    func isMediaSourceDownloaded(item: BaseItemDto, mediaSourceId: String?) -> Bool {
        guard let mediaSourceId = mediaSourceId else {
            logger.debug("No media source ID provided for download check")
            return false
        }

        logger.debug("Checking if media source \(mediaSourceId) is downloaded for item: \(item.displayTitle)")

        // Check all downloaded items
        let downloadedItems = downloadedItems()

        for downloadedTask in downloadedItems {
            // Check if this download is related to the same base item
            if downloadedTask.item.id == item.id || downloadedTask.item.seriesID == item.id {
                // Check if the downloaded item's media source matches
                if let downloadedMediaSources = downloadedTask.item.mediaSources {
                    for mediaSource in downloadedMediaSources {
                        if mediaSource.id == mediaSourceId {
                            logger.debug("Found downloaded media source: \(mediaSourceId)")
                            return true
                        }
                    }
                }
            }
        }

        logger.debug("Media source \(mediaSourceId) not found in downloads")
        return false
    }

    /// Gets all downloaded media source IDs for a given item
    func downloadedMediaSourceIds(for item: BaseItemDto) -> Set<String> {
        var downloadedIds = Set<String>()

        let downloadedItems = downloadedItems()

        for downloadedTask in downloadedItems {
            // Check if this download is related to the same base item
            if downloadedTask.item.id == item.id || downloadedTask.item.seriesID == item.id {
                // Collect all media source IDs from this download
                if let mediaSources = downloadedTask.item.mediaSources {
                    for mediaSource in mediaSources {
                        if let id = mediaSource.id {
                            downloadedIds.insert(id)
                        }
                    }
                }
            }
        }

        logger.debug("Found \(downloadedIds.count) downloaded media sources for item: \(item.displayTitle)")
        return downloadedIds
    }

    func deleteAllDownloads() {
        logger.info("Deleting all downloaded content")

        let downloadedItems = downloadedItems()
        logger.info("Found \(downloadedItems.count) items to delete")

        for item in downloadedItems {
            deleteDownload(task: item)
        }

        // Also clear any remaining downloads in progress
        for activeDownload in downloads {
            if case .downloading = activeDownload.state {
                cancel(task: activeDownload)
            }
        }
        downloads.removeAll()

        // Clear the entire downloads directory as a final cleanup
        do {
            if FileManager.default.fileExists(atPath: URL.downloads.path) {
                try FileManager.default.removeItem(at: URL.downloads)
                logger.info("Removed entire downloads directory")

                // Recreate the directory
                createDownloadDirectory()
            }
        } catch {
            logger.error("Failed to remove downloads directory: \(error)")
        }

        logger.info("Successfully deleted all downloads")
    }
}

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
    var downloadManager: Factory<DownloadManager> { self { DownloadManager() }.shared }
}

class DownloadManager: ObservableObject {

    // MARK: - Properties

    private let logger = Logger.swiftfin()
    @Injected(\.downloadDiagnostics)
    private var downloadDiagnostics: DownloadDiagnostics

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

        // Remove any existing cancelled tasks for this item
        let cancelledTasks = downloads.filter { $0.item == task.item && {
            switch $0.state {
            case .cancelled: return true
            default: return false
            }
        }($0) }

        if !cancelledTasks.isEmpty {
            logger.debug("Removing \(cancelledTasks.count) cancelled tasks for item: \(task.item.displayTitle)")
            downloads.removeAll(where: { $0.item == task.item && {
                switch $0.state {
                case .cancelled: return true
                default: return false
                }
            }($0) })
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

    func cancel(task: DownloadTask) {
        logger.info("Cancelling download for item: \(task.item.displayTitle) (ID: \(task.item.id ?? "unknown"))")
        logger.debug("Current task state: \(task.state)")
        logger.debug("Task exists in downloads array: \(downloads.contains(where: { $0.item == task.item }))")

        guard downloads.contains(where: { $0.item == task.item }) else {
            logger.warning("Attempted to cancel task that is not in downloads array")
            return
        }

        task.cancel()
        logger.debug("Called task.cancel()")

        // Update the task state to cancelled to ensure UI reflects the change
        task.state = .cancelled
        logger.debug("Updated task state to cancelled")

        // Don't immediately remove the task - let the UI observe the cancelled state
        // The task will be removed when the user starts a new download or the app restarts
        logger.info("Download cancelled successfully. Task remains in array for UI observation.")
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

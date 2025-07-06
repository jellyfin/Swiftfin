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

    private let logger = Logger.swiftfin()

    @Published
    private(set) var downloads: [DownloadTask] = []

    fileprivate init() {
        logger.info("Initializing DownloadManager")
        createDownloadDirectory()
        logger.debug("DownloadManager initialized with \(downloads.count) existing downloads")
    }

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

        // Log download folder information
        if let downloadFolder = task.item.downloadFolder {
            logger.debug("Download folder for item: \(downloadFolder)")

            // Check if folder already exists
            var isDirectory: ObjCBool = false
            let exists = FileManager.default.fileExists(atPath: downloadFolder.path, isDirectory: &isDirectory)
            logger.debug("Download folder exists: \(exists), isDirectory: \(isDirectory.boolValue)")
        } else {
            logger.error("No download folder available for item: \(task.item.displayTitle)")
        }

        task.download()
    }

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

    func downloadedItems() -> [DownloadTask] {
        logger.info("Retrieving all downloaded items")

        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            logger.debug("Found \(downloadContents.count) items in download directory: \(downloadContents)")

            let downloadedTasks = downloadContents.compactMap { itemId in
                logger.debug("Parsing download item with ID: \(itemId)")
                return parseDownloadItem(with: itemId)
            }

            logger.info("Successfully parsed \(downloadedTasks.count) downloaded items")
            return downloadedTasks
        } catch {
            logger.error("Error retrieving all downloads: \(error.localizedDescription)")
            logger.debug("Download directory path: \(URL.downloads)")
            return []
        }
    }

    private func parseDownloadItem(with id: String) -> DownloadTask? {
        logger.debug("Parsing download item with ID: \(id)")

        let itemMetadataFile = URL.downloads
            .appendingPathComponent(id)
            .appendingPathComponent("Metadata")
            .appendingPathComponent("Item.json")

        logger.debug("Metadata file path: \(itemMetadataFile)")

        guard let itemMetadataData = FileManager.default.contents(atPath: itemMetadataFile.path) else {
            logger.debug("No metadata file found at: \(itemMetadataFile)")
            return nil
        }

        logger.debug("Found metadata file, size: \(itemMetadataData.count) bytes")

        let jsonDecoder = JSONDecoder()

        guard let offlineItem = try? jsonDecoder.decode(BaseItemDto.self, from: itemMetadataData) else {
            logger.error("Failed to decode metadata JSON for item: \(id)")
            return nil
        }

        logger.debug("Successfully decoded metadata for item: \(offlineItem.displayTitle)")

        let task = DownloadTask(item: offlineItem)
        task.state = .complete
        logger.debug("Created download task with complete state")

        return task
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import Foundation
import JellyfinAPI
import Logging

/// Orchestrates download services to provide a unified download management interface
final class DownloadManager: NSObject, ObservableObject {

    private let logger = Logger.swiftfin()

    // Published state for UI
    @Published
    private(set) var downloads: [DownloadTask] = []

    // Published state tracking for each task
    @Published
    private(set) var taskStates: [UUID: DownloadTask.State] = [:]

    // Injected services
    private var sessionManager: DownloadSessionManaging
    private let urlBuilder: DownloadURLBuilding
    private let metadataManager: DownloadMetadataManaging
    private let imageManager: DownloadImageManaging
    private let fileService: DownloadFileServicing

    // Track completion status for each DownloadTask
    private var completedJobsByTask: [UUID: Set<DownloadJobType>] = [:]

    init(
        sessionManager: DownloadSessionManaging = DownloadSessionManager(),
        urlBuilder: DownloadURLBuilding = DownloadURLBuilder(),
        metadataManager: DownloadMetadataManaging? = nil,
        imageManager: DownloadImageManaging? = nil,
        fileService: DownloadFileServicing = DownloadFileService()
    ) {
        self.sessionManager = sessionManager
        self.urlBuilder = urlBuilder
        self.fileService = fileService

        // Set up dependencies for metadata and image managers
        self.metadataManager = metadataManager ?? DownloadMetadataManager(fileService: fileService)
        self.imageManager = imageManager ?? DownloadImageManager(urlBuilder: urlBuilder, fileService: fileService)

        super.init()

        // Set self as delegate for session events
        self.sessionManager.delegate = self

        // Initialize file system
        do {
            try fileService.ensureDownloadDirectory()
        } catch {
            logger.error("Failed to create downloads directory: \(error.localizedDescription)")
        }
    }

    // MARK: - Public Interface

    func clearTmp() {
        fileService.clearTmp()
    }

    // MARK: - State Management

    func getTaskState(taskID: UUID) -> DownloadTask.State {
        taskStates[taskID] ?? .ready
    }

    private func updateTaskState(taskID: UUID, state: DownloadTask.State) {
        DispatchQueue.main.async {
            self.taskStates[taskID] = state
        }
    }

    func deleteRootFolder(for task: DownloadTask) {
        guard let downloadFolder = task.item.downloadFolder else { return }
        try? FileManager.default.removeItem(at: downloadFolder)
    }

    func createFolder(for task: DownloadTask) throws {
        guard let downloadFolder = task.item.downloadFolder else { return }
        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)
    }

    func download(task: DownloadTask) {
        guard !downloads.contains(where: { $0.taskID == task.taskID }) else { return }

        downloads.append(task)
        updateTaskState(taskID: task.taskID, state: .ready)

        // Start the download using the new architecture
        Task {
            await startDownloadForTask(task)
        }
    }

    private func startDownloadForTask(_ downloadTask: DownloadTask) async {
        do {
            // Check available disk space first
            try fileService.checkAvailableDiskSpace()

            // Construct download URL
            guard let downloadURL = urlBuilder.mediaURL(
                itemId: downloadTask.item.id!,
                quality: downloadTask.quality,
                mediaSourceId: downloadTask.mediaSourceId,
                container: downloadTask.container,
                isStatic: downloadTask.isStatic,
                allowVideoStreamCopy: downloadTask.allowVideoStreamCopy,
                allowAudioStreamCopy: downloadTask.allowAudioStreamCopy,
                deviceId: downloadTask.deviceId,
                deviceProfileId: downloadTask.deviceProfileId
            ) else {
                logger.error("Failed to construct download URL for item: \(downloadTask.item.id!)")
                updateTaskState(taskID: downloadTask.taskID, state: .error(JellyfinAPIError("Failed to construct download URL")))
                return
            }

            // Initialize completion tracking
            completedJobsByTask[downloadTask.taskID] = Set<DownloadJobType>()

            // Start all downloads (media, images, metadata)
            try await startAllDownloads(for: downloadTask, with: downloadURL)

            logger.trace("Started all downloads for item: \(downloadTask.item.id!)")

        } catch {
            logger.error("Failed to start download for item: \(downloadTask.item.id!) - \(error.localizedDescription)")

            updateTaskState(taskID: downloadTask.taskID, state: .error(error))
        }
    }

    /// Starts downloading a media file from Jellyfin.
    func startDownload(
        itemId: String,
        quality: DownloadQuality = .original,
        mediaSourceId: String? = nil,
        container: String = "mp4",
        isStatic: Bool = true,
        allowVideoStreamCopy: Bool = true,
        allowAudioStreamCopy: Bool = true,
        deviceId: String? = nil,
        deviceProfileId: String? = nil
    ) -> UUID {
        // Prevent duplicate concurrent downloads for the same item/version
        if let existing = downloads.first(where: { task in
            guard task.item.id == itemId && task.mediaSourceId == mediaSourceId else { return false }
            let currentState = taskStates[task.taskID] ?? .ready
            switch currentState {
            case .ready, .downloading, .paused:
                return true
            default:
                return false
            }
        }) {
            logger
                .info(
                    "Download already in progress for item: \(itemId), mediaSourceId: \(mediaSourceId ?? "nil"). Returning existing task ID."
                )
            return existing.taskID
        }

        let taskID = UUID()
        logger.trace("Starting download for item: \(itemId) with task ID: \(taskID)")

        // Start async task to fetch item and begin download
        Task {
            do {
                // Check available disk space first
                try fileService.checkAvailableDiskSpace()

                // Fetch item details from Jellyfin API
                guard let userSession = Container.shared.currentUserSession() else {
                    logger.error("No user session available for download")
                    return
                }

                let request = Paths.getItem(itemID: itemId, userID: userSession.user.id)
                let response = try await userSession.client.send(request)
                let item = response.value

                // Create DownloadTask
                let downloadTask = DownloadTask(
                    item: item,
                    taskID: taskID,
                    mediaSourceId: mediaSourceId,
                    versionId: mediaSourceId, // Keep for backward compatibility
                    container: container,
                    quality: quality,
                    isStatic: isStatic,
                    allowVideoStreamCopy: allowVideoStreamCopy,
                    allowAudioStreamCopy: allowAudioStreamCopy,
                    deviceId: deviceId,
                    deviceProfileId: deviceProfileId
                )

                // Construct download URL
                guard let downloadURL = urlBuilder.mediaURL(
                    itemId: itemId,
                    quality: quality,
                    mediaSourceId: mediaSourceId,
                    container: container,
                    isStatic: isStatic,
                    allowVideoStreamCopy: allowVideoStreamCopy,
                    allowAudioStreamCopy: allowAudioStreamCopy,
                    deviceId: deviceId,
                    deviceProfileId: deviceProfileId
                ) else {
                    logger.error("Failed to construct download URL for item: \(itemId)")
                    return
                }

                // Add to downloads array on main thread
                await MainActor.run {
                    downloads.append(downloadTask)
                    self.taskStates[taskID] = .ready
                }

                // Initialize completion tracking
                completedJobsByTask[taskID] = Set<DownloadJobType>()

                // Start all downloads (media, images, metadata)
                try await startAllDownloads(for: downloadTask, with: downloadURL)

                logger.trace("Started all downloads for item: \(itemId)")

            } catch {
                logger.error("Failed to start download for item: \(itemId) - \(error.localizedDescription)")

                // Clean up on failure
                await MainActor.run {
                    if let index = self.downloads.firstIndex(where: { $0.taskID == taskID }) {
                        self.taskStates[taskID] = .error(error)
                    }
                }
            }
        }

        return taskID
    }

    func pauseDownload(taskID: UUID) {
        guard let task = downloads.first(where: { $0.taskID == taskID }) else { return }

        sessionManager.pause(taskID: taskID)

        // Update task state
        updateTaskState(taskID: taskID, state: .paused)
    }

    func resumeDownload(taskID: UUID) {
        guard let task = downloads.first(where: { $0.taskID == taskID }) else { return }

        Task {
            do {
                try await sessionManager.resume(taskID: taskID, with: task.resumeData)

                updateTaskState(taskID: taskID, state: .downloading(0.0))
            } catch {
                // If resume fails, restart the download
                logger.info("Resume failed, restarting download: \(error.localizedDescription)")
                await restartDownload(for: task)
            }
        }
    }

    func cancelDownload(taskID: UUID, removeFile: Bool = false) {
        guard let task = downloads.first(where: { $0.taskID == taskID }) else {
            logger.warning("Attempted to cancel non-existent download task: \(taskID)")
            return
        }

        logger.info("Cancelling download for task: \(taskID)")

        sessionManager.cancel(taskID: taskID)

        // Clean up completion tracking
        completedJobsByTask.removeValue(forKey: taskID)

        if removeFile {
            deleteRootFolder(for: task)
        }

        cancel(task: task)
    }

    func downloadStatus(taskID: UUID) -> DownloadTask.State? {
        taskStates[taskID]
    }

    func allDownloads() -> [DownloadTask] {
        downloads
    }

    // MARK: - File Operations (Delegated to FileService)

    func deleteAllDownloadedMedia() {
        logger.info("Deleting all downloaded media")

        // Cancel any active downloads first
        let activeTasks = downloads.map(\.taskID)
        for taskID in activeTasks {
            cancelDownload(taskID: taskID, removeFile: true)
        }

        do {
            try fileService.deleteAllDownloads()
            logger.info("Successfully deleted all downloaded media")
        } catch {
            logger.error("Failed to delete all downloads: \(error.localizedDescription)")
        }

        // Clear in-memory state
        reset()
    }

    @discardableResult
    func deleteDownloadedMedia(itemId: String) -> Bool {
        // First check if there's an active download for this item
        if let activeTask = downloads.first(where: { $0.item.id == itemId }) {
            cancelDownload(taskID: activeTask.taskID, removeFile: true)
            return true
        }

        do {
            return try fileService.deleteDownloads(for: itemId)
        } catch {
            logger.error("Failed to delete downloaded media for item \(itemId): \(error.localizedDescription)")
            return false
        }
    }

    func deleteDownloadedMedia(itemIds: [String]) -> [String] {
        logger.info("Deleting downloaded media for \(itemIds.count) items")

        var successfulDeletions: [String] = []

        for itemId in itemIds {
            if deleteDownloadedMedia(itemId: itemId) {
                successfulDeletions.append(itemId)
            }
        }

        logger.info("Successfully deleted \(successfulDeletions.count) out of \(itemIds.count) items")
        return successfulDeletions
    }

    // MARK: - Status and Size Methods (Delegated)

    func getTotalDownloadSize() -> Int64? {
        fileService.getTotalDownloadSize()
    }

    func getDownloadSize(itemId: String) -> Int64? {
        fileService.getDownloadSize(itemId: itemId)
    }

    func isItemDownloaded(itemId: String) -> Bool {
        fileService.isItemDownloaded(itemId: itemId)
    }

    func isItemVersionDownloaded(itemId: String, mediaSourceId: String?) -> Bool {
        logger.debug("Checking if item version is downloaded - itemId: \(itemId), mediaSourceId: \(mediaSourceId ?? "nil")")

        guard fileService.isItemDownloaded(itemId: itemId) else {
            logger.debug("Item directory not found for itemId: \(itemId)")
            return false
        }

        let downloadedVersions = metadataManager.getDownloadedVersions(for: itemId)
        logger.debug("Found \(downloadedVersions.count) downloaded versions for itemId: \(itemId)")

        // Normalize the mediaSourceId - nil should be treated as itemId
        let targetMediaSourceId = mediaSourceId ?? itemId
        logger.debug("Target mediaSourceId (normalized): \(targetMediaSourceId)")

        let hasMetadataVersion = downloadedVersions.contains { version in
            let versionMediaSourceId = version.mediaSourceId ?? itemId
            logger.debug("Comparing target '\(targetMediaSourceId)' with version '\(versionMediaSourceId)'")
            return versionMediaSourceId == targetMediaSourceId
        }

        // Also ensure the media file for this version exists on disk
        let hasMedia = fileService.hasMediaFile(for: itemId, mediaSourceId: mediaSourceId)

        let isDownloaded = hasMetadataVersion && hasMedia
        logger.debug("Item version downloaded result: \(isDownloaded)")
        return isDownloaded
    }

    func getDownloadedItemIds() -> [String] {
        fileService.getDownloadedItemIds()
    }

    // MARK: - Metadata Methods (Delegated)

    func getDownloadMetadata(for itemId: String) -> DownloadMetadata? {
        metadataManager.readMetadata(itemId: itemId)
    }

    func getDownloadedVersions(for itemId: String) -> [VersionInfo] {
        metadataManager.getDownloadedVersions(for: itemId)
    }

    // MARK: - File Operations for Tasks

    func getImageURL(for task: DownloadTask, name: String) -> URL? {
        do {
            guard let imagesFolder = task.imagesFolder else { return nil }
            let images = try FileManager.default.contentsOfDirectory(atPath: imagesFolder.path)

            guard let imageFilename = images.first(where: { $0.starts(with: name) }) else { return nil }

            return imagesFolder.appendingPathComponent(imageFilename)
        } catch {
            return nil
        }
    }

    func getMediaURL(for task: DownloadTask) -> URL? {
        do {
            guard let downloadFolder = task.item.downloadFolder else { return nil }
            let contents = try FileManager.default.contentsOfDirectory(atPath: downloadFolder.path)

            guard let mediaFilename = contents.first(where: { $0.starts(with: "Media") }) else { return nil }

            return downloadFolder.appendingPathComponent(mediaFilename)
        } catch {
            return nil
        }
    }

    // MARK: - Legacy/Compatibility Methods

    func task(for item: BaseItemDto) -> DownloadTask? {
        // For backward compatibility, return any task for this item
        if let currentlyDownloading = downloads.first(where: { $0.item.id == item.id }) {
            return currentlyDownloading
        } else {
            return metadataManager.parseDownloadItem(with: item.id!)
        }
    }

    func cancel(task: DownloadTask) {
        guard downloads.contains(where: { $0.taskID == task.taskID }) else { return }

        updateTaskState(taskID: task.taskID, state: .cancelled)
        remove(task: task)
    }

    func remove(task: DownloadTask) {
        downloads.removeAll(where: { $0.taskID == task.taskID })
        taskStates.removeValue(forKey: task.taskID)
    }

    func reset() {
        downloads.removeAll()
        taskStates.removeAll()
    }

    func downloadedItems() -> [DownloadTask] {
        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            return downloadContents.compactMap { metadataManager.parseDownloadItem(with: $0) }
        } catch {
            logger.error("Error retrieving all downloads: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: - Debug Methods (Delegated)

    func debugListDownloadedItems() {
        metadataManager.debugListDownloadedItems()
    }

    func debugCheckSpecificVersion(itemId: String, mediaSourceId: String?) {
        metadataManager.debugCheckSpecificVersion(itemId: itemId, mediaSourceId: mediaSourceId)
    }

    // MARK: - Private Helpers

    private func startAllDownloads(for downloadTask: DownloadTask, with mediaURL: URL) async throws {
        // Ensure the root download folder exists before any work
        if let downloadFolder = downloadTask.item.downloadFolder {
            try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)
        }

        // Save metadata first so presence checks work early
        try metadataManager.writeMetadata(for: downloadTask)
        markJobCompleted(taskID: downloadTask.taskID, jobType: .metadata)

        // Start media download
        try await sessionManager.start(url: mediaURL, taskID: downloadTask.taskID, jobType: .media)

        updateTaskState(taskID: downloadTask.taskID, state: .downloading(0.0))

        // Start image downloads (non-blocking)
        imageManager.downloadImages(for: downloadTask) { result in
            switch result {
            case .success:
                self.logger.trace("Image downloads completed for: \(downloadTask.item.displayTitle)")
            case let .failure(error):
                self.logger.warning("Some image downloads failed: \(error.localizedDescription)")
            }
        }

        // Add a safety timeout to ensure downloads complete even if images hang
        Task {
            try? await Task.sleep(nanoseconds: 60_000_000_000) // 60 seconds

            // Check if download is still pending and complete it if essential parts are done
            if let currentState = taskStates[downloadTask.taskID],
               case .downloading = currentState,
               isTaskFullyCompleted(taskID: downloadTask.taskID)
            {
                updateTaskState(taskID: downloadTask.taskID, state: .complete)
                logger.info("Download completed via timeout safety mechanism: \(downloadTask.item.displayTitle)")
            }
        }
    }

    private func restartDownload(for task: DownloadTask) async {
        guard let downloadURL = urlBuilder.mediaURL(
            itemId: task.item.id!,
            quality: task.quality,
            mediaSourceId: task.mediaSourceId,
            container: task.container,
            isStatic: task.isStatic,
            allowVideoStreamCopy: task.allowVideoStreamCopy,
            allowAudioStreamCopy: task.allowAudioStreamCopy,
            deviceId: task.deviceId,
            deviceProfileId: task.deviceProfileId
        ) else {
            logger.error("Failed to construct download URL for restart")
            return
        }

        do {
            try await startAllDownloads(for: task, with: downloadURL)
        } catch {
            logger.error("Failed to restart download: \(error.localizedDescription)")
        }
    }

    // MARK: - Completion Tracking

    private func markJobCompleted(taskID: UUID, jobType: DownloadJobType) {
        var completed = completedJobsByTask[taskID] ?? Set<DownloadJobType>()
        completed.insert(jobType)
        completedJobsByTask[taskID] = completed
    }

    private func isTaskFullyCompleted(taskID: UUID) -> Bool {
        guard let completed = completedJobsByTask[taskID] else { return false }

        // Only require essential downloads - media and metadata
        // Images are optional and shouldn't block completion
        let requiredJobs: Set<DownloadJobType> = [.media, .metadata]

        return requiredJobs.isSubset(of: completed)
    }
}

// MARK: - DownloadSessionDelegate

extension DownloadManager: DownloadSessionDelegate {

    func sessionDidCompleteDownload(taskIdentifier: Int, location: URL, response: URLResponse?) {
        guard let downloadJob = sessionManager.getDownloadJob(for: taskIdentifier),
              let downloadTaskIndex = downloads.firstIndex(where: { $0.taskID == downloadJob.taskID })
        else {
            logger.error("Could not find corresponding DownloadTask for URLSessionDownloadTask: \(taskIdentifier)")
            return
        }

        let swiftfinDownloadTask = downloads[downloadTaskIndex]

        // Move file to final destination
        do {
            switch downloadJob.type {
            case .media:
                try fileService.moveMediaFile(
                    from: location,
                    to: swiftfinDownloadTask.item.downloadFolder!,
                    for: swiftfinDownloadTask,
                    response: response
                )
            case .backdropImage, .primaryImage:
                try fileService.moveImageFile(
                    from: location,
                    to: swiftfinDownloadTask.item.downloadFolder!,
                    for: swiftfinDownloadTask,
                    response: response,
                    jobType: downloadJob.type
                )
            case .metadata:
                // Metadata is handled separately
                break
            case .subtitle:
                // TODO: Handle subtitle files
                break
            }

            // Track completion
            markJobCompleted(taskID: downloadJob.taskID, jobType: downloadJob.type)

            // Check completion status - complete when essential downloads are done
            if isTaskFullyCompleted(taskID: downloadJob.taskID) {
                updateTaskState(taskID: downloadJob.taskID, state: .complete)
                logger.trace("Essential downloads completed for: \(swiftfinDownloadTask.item.displayTitle)")
            }

        } catch {
            logger.error("Failed to move downloaded file: \(error.localizedDescription)")

            updateTaskState(taskID: downloadJob.taskID, state: .error(error))
        }

        // Clean up active job
        sessionManager.removeDownloadJob(for: taskIdentifier)
    }

    func sessionDidUpdateProgress(taskIdentifier: Int, progress: Double) {
        guard let downloadJob = sessionManager.getDownloadJob(for: taskIdentifier),
              let downloadTaskIndex = downloads.firstIndex(where: { $0.taskID == downloadJob.taskID })
        else {
            return
        }

        // Only update progress for media downloads to avoid confusing UI
        if case .media = downloadJob.type {
            updateTaskState(taskID: downloadJob.taskID, state: .downloading(progress))
        }
    }

    func sessionDidCompleteWithError(taskIdentifier: Int, error: Error?) {
        guard let error = error,
              let downloadJob = sessionManager.getDownloadJob(for: taskIdentifier),
              let downloadTaskIndex = downloads.firstIndex(where: { $0.taskID == downloadJob.taskID })
        else {
            return
        }

        let swiftfinDownloadTask = downloads[downloadTaskIndex]

        // Check if we should retry
        if swiftfinDownloadTask.shouldRetry(for: error) {
            logger.info("Retrying download for: \(swiftfinDownloadTask.item.displayTitle) (attempt \(swiftfinDownloadTask.retryCount + 1))")

            // Update retry count in our tracking
            if var updatedTask = downloads.first(where: { $0.taskID == swiftfinDownloadTask.taskID }) {
                updatedTask.incrementRetryCount()
                // Update the task in our array
                if let index = downloads.firstIndex(where: { $0.taskID == swiftfinDownloadTask.taskID }) {
                    downloads[index] = updatedTask
                }
            }

            // Exponential backoff: 2^retryCount seconds
            let delay = pow(2.0, Double(swiftfinDownloadTask.retryCount + 1))

            DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                Task {
                    await self.retrySpecificDownload(for: swiftfinDownloadTask, jobType: downloadJob.type)
                }
            }

        } else {
            // Handle failed downloads based on type
            switch downloadJob.type {
            case .media, .metadata:
                // Media and metadata download failures are critical
                updateTaskState(taskID: downloadJob.taskID, state: .error(error))
            case .backdropImage, .primaryImage, .subtitle:
                // Image and subtitle download failures are not critical
                logger
                    .warning("\(downloadJob.type) download failed, checking if task can complete without it: \(error.localizedDescription)")

                if isTaskFullyCompleted(taskID: downloadJob.taskID) {
                    updateTaskState(taskID: downloadJob.taskID, state: .complete)
                    logger.trace("Task completed despite \(downloadJob.type) download failure: \(swiftfinDownloadTask.item.displayTitle)")
                }
            }
        }

        // Clean up active job
        sessionManager.removeDownloadJob(for: taskIdentifier)
    }

    func sessionDidFinishBackgroundEvents() {
        logger.trace("Background URLSession did finish events")

        DispatchQueue.main.async {
            // TODO: Call completion handler for background app refresh
        }
    }

    private func retrySpecificDownload(for downloadTask: DownloadTask, jobType: DownloadJobType) async {
        switch jobType {
        case .media:
            await retryMediaDownload(for: downloadTask)
        case .backdropImage, .primaryImage:
            await retryImageDownload(for: downloadTask, imageType: jobType)
        case .metadata:
            // Metadata doesn't need retry, just regenerate
            do {
                try metadataManager.writeMetadata(for: downloadTask)
                markJobCompleted(taskID: downloadTask.taskID, jobType: .metadata)
            } catch {
                logger.error("Failed to save metadata on retry: \(error.localizedDescription)")
            }
        case .subtitle:
            // TODO: Implement subtitle retry
            break
        }
    }

    private func retryMediaDownload(for downloadTask: DownloadTask) async {
        guard let downloadURL = urlBuilder.mediaURL(
            itemId: downloadTask.item.id!,
            quality: downloadTask.quality,
            mediaSourceId: downloadTask.mediaSourceId,
            container: downloadTask.container,
            isStatic: downloadTask.isStatic,
            allowVideoStreamCopy: downloadTask.allowVideoStreamCopy,
            allowAudioStreamCopy: downloadTask.allowAudioStreamCopy,
            deviceId: downloadTask.deviceId,
            deviceProfileId: downloadTask.deviceProfileId
        ) else {
            logger.error("Failed to construct download URL for retry of item: \(downloadTask.item.id!)")
            return
        }

        do {
            try await sessionManager.start(url: downloadURL, taskID: downloadTask.taskID, jobType: .media)
        } catch {
            logger.error("Failed to retry media download: \(error.localizedDescription)")
        }
    }

    private func retryImageDownload(for downloadTask: DownloadTask, imageType: DownloadJobType) async {
        guard let imageURL = urlBuilder.imageURL(for: downloadTask.item, type: imageType) else {
            logger.error("Failed to create image URL for retry")
            return
        }

        do {
            try await sessionManager.start(url: imageURL, taskID: downloadTask.taskID, jobType: imageType)
        } catch {
            logger.error("Failed to retry image download: \(error.localizedDescription)")
        }
    }
}

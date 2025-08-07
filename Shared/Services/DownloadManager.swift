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

class DownloadManager: NSObject, ObservableObject {

    enum DownloadJobType: Hashable, Equatable {
        case media
        case backdropImage
        case primaryImage
        case metadata
        case subtitle(index: Int)
    }

    enum DownloadQuality: Hashable, Equatable {
        case original
        case high // 1080p, ~4 Mbps
        case medium // 720p, ~2 Mbps
        case low // 480p, ~1 Mbps
        case custom(TranscodingParameters)
    }

    struct TranscodingParameters: Hashable, Equatable {
        let maxWidth: Int?
        let maxHeight: Int?
        let videoBitRate: Int?
        let audioBitRate: Int?
        let enableAutoStreamCopy: Bool

        init(
            maxWidth: Int? = nil,
            maxHeight: Int? = nil,
            videoBitRate: Int? = nil,
            audioBitRate: Int? = nil,
            enableAutoStreamCopy: Bool = true
        ) {
            self.maxWidth = maxWidth
            self.maxHeight = maxHeight
            self.videoBitRate = videoBitRate
            self.audioBitRate = audioBitRate
            self.enableAutoStreamCopy = enableAutoStreamCopy
        }

        static let highQuality = TranscodingParameters(
            maxWidth: 1920,
            maxHeight: 1080,
            videoBitRate: 4_000_000,
            audioBitRate: 128_000
        )

        static let mediumQuality = TranscodingParameters(
            maxWidth: 1280,
            maxHeight: 720,
            videoBitRate: 2_000_000,
            audioBitRate: 128_000
        )

        static let lowQuality = TranscodingParameters(
            maxWidth: 854,
            maxHeight: 480,
            videoBitRate: 1_000_000,
            audioBitRate: 96000
        )
    }

    struct DownloadJob {
        let type: DownloadJobType
        let taskID: UUID
        let url: URL
        let destinationPath: String
    }

    private let logger = Logger.swiftfin()

    @Published
    private(set) var downloads: [DownloadTask] = []

    // Background URLSession infrastructure
    private var backgroundSession: URLSession!
    private let sessionQueue = DispatchQueue(label: "downloadManager.session", qos: .utility)
    private static let backgroundSessionIdentifier = "com.jellyfin.swiftfin.background-downloads"

    // Mapping between URLSessionDownloadTask identifier and DownloadJob
    private var activeJobs: [Int: DownloadJob] = [:]

    // Track completion status for each DownloadTask
    private var completedJobsByTask: [UUID: Set<DownloadJobType>] = [:]

    override fileprivate init() {
        super.init()
        setupBackgroundSession()
        createDownloadDirectory()
        recoverActiveDownloads()
    }

    private func recoverActiveDownloads() {
        // Recover active downloads from background session
        backgroundSession.getAllTasks { tasks in
            for task in tasks {
                if let downloadTask = task as? URLSessionDownloadTask {
                    self.logger.trace("Found active background download task: \(downloadTask.taskIdentifier)")

                    // TODO: We need to associate this with a DownloadTask
                    // For now, just log that we found active tasks
                    // In a full implementation, we would restore the DownloadTask from persistence
                }
            }
        }
    }

    private func setupBackgroundSession() {
        let config = URLSessionConfiguration.background(withIdentifier: Self.backgroundSessionIdentifier)
        config.sessionSendsLaunchEvents = true
        config.isDiscretionary = false
        config.allowsCellularAccess = true

        backgroundSession = URLSession(
            configuration: config,
            delegate: self,
            delegateQueue: nil
        )
    }

    private func createDownloadDirectory() {

        try? FileManager.default.createDirectory(
            at: URL.downloads,
            withIntermediateDirectories: true
        )
    }

    func clearTmp() {
        do {
            try Folder(path: URL.tmp.path).files.delete()

            logger.trace("Cleared tmp directory")
        } catch {
            logger.error("Unable to clear tmp directory: \(error.localizedDescription)")
        }
    }

    func download(task: DownloadTask) {
        guard !downloads.contains(where: { $0.item == task.item }) else { return }

        downloads.append(task)

        task.download()
    }

    /// Starts downloading a media file from Jellyfin.
    /// - Parameters:
    ///   - itemId: The Jellyfin Item ID of the movie or episode to download.
    ///   - quality: The download quality - original file or transcoded quality level.
    ///   - mediaSourceId: Optional MediaSource ID to select a specific version or quality. If nil, defaults to the primary source.
    ///   - container: Desired file container (e.g. "mp4", "mkv").
    ///   - isStatic: Stream the original file without re-encoding (static=true). Ignored when using transcoded quality.
    ///   - allowVideoStreamCopy: Permit direct copy of the video stream when possible.
    ///   - allowAudioStreamCopy: Permit direct copy of the audio stream when possible.
    ///   - deviceId: Optional client device ID for server-side session tracking.
    ///   - deviceProfileId: Optional device profile ID for DLNA or encoding profiles.
    /// - Returns: A UUID to identify and manage the download task.
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
        let taskID = UUID()
        logger.trace("Starting download for item: \(itemId) with task ID: \(taskID)")

        // Start async task to fetch item and begin download
        Task {
            do {
                // Check available disk space first
                try checkAvailableDiskSpace()

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
                    versionId: mediaSourceId, // Use mediaSourceId as versionId for now
                    container: container,
                    quality: quality,
                    isStatic: isStatic,
                    allowVideoStreamCopy: allowVideoStreamCopy,
                    allowAudioStreamCopy: allowAudioStreamCopy,
                    deviceId: deviceId,
                    deviceProfileId: deviceProfileId
                )

                // Construct download URL
                guard let downloadURL = constructMediaURL(
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
                        self.downloads[index].state = .error(error)
                    }
                }
            }
        }

        return taskID
    }

    private func startAllDownloads(for downloadTask: DownloadTask, with mediaURL: URL) async throws {
        // Start media download
        try await startSpecificDownload(for: downloadTask, jobType: .media, url: mediaURL)

        // Start image downloads
        if let backdropURL = createImageDownloadURL(for: downloadTask.item, imageType: .backdropImage) {
            try await startSpecificDownload(for: downloadTask, jobType: .backdropImage, url: backdropURL)
        }

        if let primaryURL = createImageDownloadURL(for: downloadTask.item, imageType: .primaryImage) {
            try await startSpecificDownload(for: downloadTask, jobType: .primaryImage, url: primaryURL)
        }

        // Start metadata download (we'll create a dummy URL for this since metadata is generated locally)
        try await startMetadataJob(for: downloadTask)
    }

    private func startSpecificDownload(for downloadTask: DownloadTask, jobType: DownloadJobType, url: URL) async throws {
        let urlRequest = URLRequest(url: url)
        let urlDownloadTask = backgroundSession.downloadTask(with: urlRequest)

        let downloadJob = DownloadJob(
            type: jobType,
            taskID: downloadTask.taskID,
            url: url,
            destinationPath: "" // Will be determined during file move
        )

        // Associate URLSessionDownloadTask with DownloadJob
        activeJobs[urlDownloadTask.taskIdentifier] = downloadJob

        urlDownloadTask.resume()

        if case .media = jobType {
            await MainActor.run {
                downloadTask.state = .downloading(0.0)
            }
        }

        logger.trace("Started \(jobType) download for: \(downloadTask.item.displayTitle)")
    }

    private func startMetadataJob(for downloadTask: DownloadTask) async throws {
        // Metadata is generated locally, so we immediately mark it as completed
        markJobCompleted(taskID: downloadTask.taskID, jobType: .metadata)

        // Save metadata files
        try saveAllMetadata(for: downloadTask)
    }

    func pauseDownload(taskID: UUID) {
        guard let task = downloads.first(where: { $0.taskID == taskID }) else { return }

        // Find all corresponding URLSessionDownloadTasks for this DownloadTask
        let relatedTasks = activeJobs.filter { $0.value.taskID == taskID }

        for (urlTaskIdentifier, downloadJob) in relatedTasks {
            backgroundSession.getAllTasks { tasks in
                if let urlTask = tasks.first(where: { $0.taskIdentifier == urlTaskIdentifier }) as? URLSessionDownloadTask {
                    urlTask.cancel { resumeData in
                        DispatchQueue.main.async {
                            // Store resume data for media downloads only
                            if case .media = downloadJob.type {
                                task.resumeData = resumeData
                                task.state = .paused
                            }
                        }
                    }
                }
            }

            // Remove from task mapping since task is cancelled
            activeJobs.removeValue(forKey: urlTaskIdentifier)
        }
    }

    func resumeDownload(taskID: UUID) {
        guard let task = downloads.first(where: { $0.taskID == taskID }) else { return }

        // For now, we'll only support resuming the media download
        // Other downloads (images, metadata) will be restarted from the beginning
        if let resumeData = task.resumeData {
            // Resume media download
            let urlDownloadTask = backgroundSession.downloadTask(withResumeData: resumeData)

            let downloadJob = DownloadJob(
                type: .media,
                taskID: taskID,
                url: URL(string: "")!, // URL not needed for resume
                destinationPath: ""
            )

            activeJobs[urlDownloadTask.taskIdentifier] = downloadJob
            urlDownloadTask.resume()

            DispatchQueue.main.async {
                task.state = .downloading(0.0)
            }
        } else {
            // Restart all downloads from the beginning
            Task {
                do {
                    let downloadURL = constructMediaURL(
                        itemId: task.item.id!,
                        quality: task.quality,
                        mediaSourceId: task.mediaSourceId,
                        container: task.container,
                        isStatic: task.isStatic,
                        allowVideoStreamCopy: task.allowVideoStreamCopy,
                        allowAudioStreamCopy: task.allowAudioStreamCopy,
                        deviceId: task.deviceId,
                        deviceProfileId: task.deviceProfileId
                    )

                    guard let url = downloadURL else {
                        logger.error("Failed to construct download URL for resume")
                        return
                    }

                    try await startAllDownloads(for: task, with: url)
                } catch {
                    logger.error("Failed to resume download: \(error.localizedDescription)")
                }
            }
        }
    }

    func cancelDownload(taskID: UUID, removeFile: Bool = false) {
        guard let task = downloads.first(where: { $0.taskID == taskID }) else { return }

        // Cancel all URLSession tasks for this DownloadTask
        let relatedTasks = activeJobs.filter { $0.value.taskID == taskID }

        for (urlTaskIdentifier, _) in relatedTasks {
            backgroundSession.getAllTasks { tasks in
                if let urlTask = tasks.first(where: { $0.taskIdentifier == urlTaskIdentifier }) {
                    urlTask.cancel()
                }
            }

            // Remove from task mapping
            activeJobs.removeValue(forKey: urlTaskIdentifier)
        }

        // Clean up completion tracking
        completedJobsByTask.removeValue(forKey: taskID)

        if removeFile {
            task.deleteRootFolder()
        }

        cancel(task: task)
    }

    func downloadStatus(taskID: UUID) -> DownloadTask.State? {
        downloads.first(where: { $0.taskID == taskID })?.state
    }

    func allDownloads() -> [DownloadTask] {
        downloads
    }

    /// Deletes all downloaded media files and folders from the device.
    /// This will permanently remove all downloaded content.
    func deleteAllDownloadedMedia() {
        logger.info("Deleting all downloaded media")

        // Cancel any active downloads first
        let activeTasks = downloads.map(\.taskID)
        for taskID in activeTasks {
            cancelDownload(taskID: taskID, removeFile: true)
        }

        // Clear the downloads folder entirely
        do {
            let downloadFolders = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)

            for folderName in downloadFolders {
                let folderPath = URL.downloads.appendingPathComponent(folderName)
                try FileManager.default.removeItem(at: folderPath)
                logger.trace("Deleted download folder: \(folderName)")
            }

            logger.info("Successfully deleted all downloaded media")
        } catch {
            logger.error("Failed to delete all downloads: \(error.localizedDescription)")
        }

        // Clear in-memory state
        reset()
    }

    /// Deletes downloaded media for a specific item by its ID.
    /// - Parameter itemId: The Jellyfin item ID to delete
    /// - Returns: True if the item was found and deleted, false otherwise
    @discardableResult
    func deleteDownloadedMedia(itemId: String) -> Bool {
        logger.info("Deleting downloaded media for item: \(itemId)")

        // First check if there's an active download for this item
        if let activeTask = downloads.first(where: { $0.item.id == itemId }) {
            cancelDownload(taskID: activeTask.taskID, removeFile: true)
            return true
        }

        // Check if there's a completed download
        let downloadPath = URL.downloads.appendingPathComponent(itemId)

        guard FileManager.default.fileExists(atPath: downloadPath.path) else {
            logger.warning("No downloaded media found for item: \(itemId)")
            return false
        }

        do {
            try FileManager.default.removeItem(at: downloadPath)
            logger.info("Successfully deleted downloaded media for item: \(itemId)")
            return true
        } catch {
            logger.error("Failed to delete downloaded media for item \(itemId): \(error.localizedDescription)")
            return false
        }
    }

    /// Deletes downloaded media for multiple items.
    /// - Parameter itemIds: Array of Jellyfin item IDs to delete
    /// - Returns: Array of item IDs that were successfully deleted
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

    /// Gets the total storage size used by all downloaded media.
    /// - Returns: Size in bytes, or nil if unable to calculate
    func getTotalDownloadSize() -> Int64? {
        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            var totalSize: Int64 = 0

            for itemFolder in downloadContents {
                let itemPath = URL.downloads.appendingPathComponent(itemFolder)
                let folderSize = try getFolderSize(at: itemPath)
                totalSize += folderSize
            }

            return totalSize
        } catch {
            logger.error("Failed to calculate total download size: \(error.localizedDescription)")
            return nil
        }
    }

    /// Gets the storage size for a specific downloaded item.
    /// - Parameter itemId: The Jellyfin item ID
    /// - Returns: Size in bytes, or nil if item not found or error occurred
    func getDownloadSize(itemId: String) -> Int64? {
        let itemPath = URL.downloads.appendingPathComponent(itemId)

        guard FileManager.default.fileExists(atPath: itemPath.path) else {
            return nil
        }

        do {
            return try getFolderSize(at: itemPath)
        } catch {
            logger.error("Failed to calculate download size for item \(itemId): \(error.localizedDescription)")
            return nil
        }
    }

    /// Helper method to calculate folder size recursively.
    private func getFolderSize(at url: URL) throws -> Int64 {
        let resourceKeys: [URLResourceKey] = [.isRegularFileKey, .fileAllocatedSizeKey]
        let directoryEnumerator = FileManager.default.enumerator(
            at: url,
            includingPropertiesForKeys: resourceKeys,
            options: [.skipsHiddenFiles]
        )

        var totalSize: Int64 = 0

        for case let fileURL as URL in directoryEnumerator ?? [] {
            let resourceValues = try fileURL.resourceValues(forKeys: Set(resourceKeys))

            if resourceValues.isRegularFile == true {
                totalSize += Int64(resourceValues.fileAllocatedSize ?? 0)
            }
        }

        return totalSize
    }

    /// Checks if a specific item is downloaded.
    /// - Parameter itemId: The Jellyfin item ID to check
    /// - Returns: True if the item is downloaded, false otherwise
    func isItemDownloaded(itemId: String) -> Bool {
        let downloadPath = URL.downloads.appendingPathComponent(itemId)
        var isDirectory: ObjCBool = false

        let exists = FileManager.default.fileExists(atPath: downloadPath.path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    /// Gets a list of all downloaded item IDs.
    /// - Returns: Array of item IDs that have been downloaded
    func getDownloadedItemIds() -> [String] {
        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            return downloadContents.filter { itemId in
                // Verify it's a valid download by checking for metadata
                let metadataPath = URL.downloads
                    .appendingPathComponent(itemId)
                    .appendingPathComponent("Metadata")
                    .appendingPathComponent("Item.json")
                return FileManager.default.fileExists(atPath: metadataPath.path)
            }
        } catch {
            logger.error("Failed to get downloaded item IDs: \(error.localizedDescription)")
            return []
        }
    }

    // MARK: Private Helper Methods

    private func markJobCompleted(taskID: UUID, jobType: DownloadJobType) {
        var completed = completedJobsByTask[taskID] ?? Set<DownloadJobType>()
        completed.insert(jobType)
        completedJobsByTask[taskID] = completed
    }

    private func isTaskFullyCompleted(taskID: UUID) -> Bool {
        guard let completed = completedJobsByTask[taskID] else { return false }

        // Define required downloads based on item type
        let requiredJobs: Set<DownloadJobType> = [.media, .backdropImage, .primaryImage, .metadata]

        return requiredJobs.isSubset(of: completed)
    }

    private func checkAvailableDiskSpace() throws {
        let fileURL = URL.downloads
        let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])

        guard let capacity = values.volumeAvailableCapacityForImportantUsage else {
            throw DownloadTask.DownloadError.notEnoughStorage
        }

        // Require at least 100MB free space
        let minimumFreeSpace: Int64 = 100 * 1024 * 1024

        if capacity < minimumFreeSpace {
            throw DownloadTask.DownloadError.notEnoughStorage
        }
    }

    private func constructMediaURL(
        itemId: String,
        quality: DownloadQuality,
        mediaSourceId: String?,
        container: String,
        isStatic: Bool,
        allowVideoStreamCopy: Bool,
        allowAudioStreamCopy: Bool,
        deviceId: String?,
        deviceProfileId: String?
    ) -> URL? {
        switch quality {
        case .original:
            return constructDownloadURL(
                itemId: itemId,
                mediaSourceId: mediaSourceId,
                container: container,
                isStatic: isStatic,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        case .high:
            return constructStreamingURL(
                itemId: itemId,
                transcodingParams: .highQuality,
                mediaSourceId: mediaSourceId,
                container: container,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        case .medium:
            return constructStreamingURL(
                itemId: itemId,
                transcodingParams: .mediumQuality,
                mediaSourceId: mediaSourceId,
                container: container,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        case .low:
            return constructStreamingURL(
                itemId: itemId,
                transcodingParams: .lowQuality,
                mediaSourceId: mediaSourceId,
                container: container,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        case let .custom(params):
            return constructStreamingURL(
                itemId: itemId,
                transcodingParams: params,
                mediaSourceId: mediaSourceId,
                container: container,
                allowVideoStreamCopy: allowVideoStreamCopy,
                allowAudioStreamCopy: allowAudioStreamCopy,
                deviceId: deviceId,
                deviceProfileId: deviceProfileId
            )
        }
    }

    private func constructDownloadURL(
        itemId: String,
        mediaSourceId: String?,
        container: String,
        isStatic: Bool,
        allowVideoStreamCopy: Bool,
        allowAudioStreamCopy: Bool,
        deviceId: String?,
        deviceProfileId: String?
    ) -> URL? {
        guard let userSession = Container.shared.currentUserSession() else { return nil }

        // Construct the download request with enhanced parameters
        var queryItems: [URLQueryItem] = []

        if let mediaSourceId = mediaSourceId {
            queryItems.append(URLQueryItem(name: "MediaSourceId", value: mediaSourceId))
        }

        queryItems.append(URLQueryItem(name: "Container", value: container))
        queryItems.append(URLQueryItem(name: "Static", value: isStatic.description))
        queryItems.append(URLQueryItem(name: "AllowVideoStreamCopy", value: allowVideoStreamCopy.description))
        queryItems.append(URLQueryItem(name: "AllowAudioStreamCopy", value: allowAudioStreamCopy.description))

        if let deviceId = deviceId {
            queryItems.append(URLQueryItem(name: "DeviceId", value: deviceId))
        }

        if let deviceProfileId = deviceProfileId {
            queryItems.append(URLQueryItem(name: "DeviceProfileId", value: deviceProfileId))
        }

        // Build the URL path
        let path = "/Items/\(itemId)/Download"

        guard let baseURL = userSession.client.fullURL(with: path) else { return nil }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }

        components.queryItems = queryItems

        // Add API key to query if needed
        if let accessToken = userSession.client.accessToken {
            components.queryItems?.append(URLQueryItem(name: "api_key", value: accessToken))
        }

        return components.url
    }

    private func constructStreamingURL(
        itemId: String,
        transcodingParams: TranscodingParameters,
        mediaSourceId: String?,
        container: String,
        allowVideoStreamCopy: Bool,
        allowAudioStreamCopy: Bool,
        deviceId: String?,
        deviceProfileId: String?
    ) -> URL? {
        guard let userSession = Container.shared.currentUserSession() else { return nil }

        // Use the streaming endpoint for transcoded downloads
        let path = "/Videos/\(itemId)/stream.\(container)"

        guard let baseURL = userSession.client.fullURL(with: path) else { return nil }
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: false) else { return nil }

        var queryItems: [URLQueryItem] = []

        // Force transcoding by setting static=false
        queryItems.append(URLQueryItem(name: "static", value: "false"))

        if let mediaSourceId = mediaSourceId {
            queryItems.append(URLQueryItem(name: "MediaSourceId", value: mediaSourceId))
        }

        queryItems.append(URLQueryItem(name: "Container", value: container))
        queryItems.append(URLQueryItem(name: "AllowVideoStreamCopy", value: allowVideoStreamCopy.description))
        queryItems.append(URLQueryItem(name: "AllowAudioStreamCopy", value: allowAudioStreamCopy.description))

        // Add transcoding parameters
        if let maxWidth = transcodingParams.maxWidth {
            queryItems.append(URLQueryItem(name: "maxWidth", value: String(maxWidth)))
        }

        if let maxHeight = transcodingParams.maxHeight {
            queryItems.append(URLQueryItem(name: "maxHeight", value: String(maxHeight)))
        }

        if let videoBitRate = transcodingParams.videoBitRate {
            queryItems.append(URLQueryItem(name: "videoBitRate", value: String(videoBitRate)))
        }

        if let audioBitRate = transcodingParams.audioBitRate {
            queryItems.append(URLQueryItem(name: "audioBitRate", value: String(audioBitRate)))
        }

        queryItems.append(URLQueryItem(name: "enableAutoStreamCopy", value: transcodingParams.enableAutoStreamCopy.description))

        if let deviceId = deviceId {
            queryItems.append(URLQueryItem(name: "DeviceId", value: deviceId))
        }

        if let deviceProfileId = deviceProfileId {
            queryItems.append(URLQueryItem(name: "DeviceProfileId", value: deviceProfileId))
        }

        components.queryItems = queryItems

        // Add API key to query if needed
        if let accessToken = userSession.client.accessToken {
            components.queryItems?.append(URLQueryItem(name: "api_key", value: accessToken))
        }

        return components.url
    }

    private func createImageDownloadURL(for item: BaseItemDto, imageType: DownloadJobType) -> URL? {
        let imageURL: URL?

        switch imageType {
        case .backdropImage:
            switch item.type {
            case .movie, .series:
                imageURL = item.imageSource(.backdrop, maxWidth: 600).url
            case .episode:
                imageURL = item.imageSource(.primary, maxWidth: 600).url
            default:
                return nil
            }
        case .primaryImage:
            switch item.type {
            case .movie, .series:
                imageURL = item.imageSource(.primary, maxWidth: 300).url
            default:
                return nil
            }
        default:
            return nil
        }

        return imageURL
    }

    func task(for item: BaseItemDto) -> DownloadTask? {
        if let currentlyDownloading = downloads.first(where: { $0.item == item }) {
            return currentlyDownloading
        } else {
            var isDir: ObjCBool = true
            guard let downloadFolder = item.downloadFolder else { return nil }
            guard FileManager.default.fileExists(atPath: downloadFolder.path, isDirectory: &isDir) else { return nil }

            return parseDownloadItem(with: item.id!)
        }
    }

    func cancel(task: DownloadTask) {
        guard downloads.contains(where: { $0.item == task.item }) else { return }

        task.cancel()

        remove(task: task)
    }

    func remove(task: DownloadTask) {
        downloads.removeAll(where: { $0.item == task.item })
    }

    func reset() {
        downloads.removeAll()
    }

    func downloadedItems() -> [DownloadTask] {
        do {
            let downloadContents = try FileManager.default.contentsOfDirectory(atPath: URL.downloads.path)
            return downloadContents.compactMap(parseDownloadItem(with:))
        } catch {
            logger.error("Error retrieving all downloads: \(error.localizedDescription)")

            return []
        }
    }

    private func parseDownloadItem(with id: String) -> DownloadTask? {

        let itemMetadataFile = URL.downloads
            .appendingPathComponent(id)
            .appendingPathComponent("Metadata")
            .appendingPathComponent("Item.json")

        guard let itemMetadataData = FileManager.default.contents(atPath: itemMetadataFile.path) else { return nil }

        let jsonDecoder = JSONDecoder()

        guard let offlineItem = try? jsonDecoder.decode(BaseItemDto.self, from: itemMetadataData) else { return nil }

        let task = DownloadTask(item: offlineItem)
        task.state = .complete
        return task
    }
}

// MARK: URLSessionDownloadDelegate

extension DownloadManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        logger.trace("Download completed: \(downloadTask.taskIdentifier)")

        guard let downloadJob = activeJobs[downloadTask.taskIdentifier],
              let downloadTaskIndex = downloads.firstIndex(where: { $0.taskID == downloadJob.taskID })
        else {
            logger.error("Could not find corresponding DownloadTask for URLSessionDownloadTask: \(downloadTask.taskIdentifier)")
            return
        }

        let swiftfinDownloadTask = downloads[downloadTaskIndex]

        // Move file to final destination
        do {
            try moveDownloadedFile(from: location, for: swiftfinDownloadTask, with: downloadTask.response, jobType: downloadJob.type)

            // Track completion
            markJobCompleted(taskID: downloadJob.taskID, jobType: downloadJob.type)

            // Check if all downloads for this task are complete
            if isTaskFullyCompleted(taskID: downloadJob.taskID) {
                DispatchQueue.main.async {
                    self.downloads[downloadTaskIndex].state = .complete
                }

                logger.trace("All downloads completed for: \(swiftfinDownloadTask.item.displayTitle)")
            }

        } catch {
            logger.error("Failed to move downloaded file: \(error.localizedDescription)")

            DispatchQueue.main.async {
                self.downloads[downloadTaskIndex].state = .error(error)
            }
        }

        // Clean up active job
        activeJobs.removeValue(forKey: downloadTask.taskIdentifier)
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        guard let downloadJob = activeJobs[downloadTask.taskIdentifier],
              let downloadTaskIndex = downloads.firstIndex(where: { $0.taskID == downloadJob.taskID })
        else {
            return
        }

        // Only update progress for media downloads to avoid confusing UI
        if case .media = downloadJob.type {
            DispatchQueue.main.async {
                self.downloads[downloadTaskIndex].state = .downloading(progress)
            }
        }

        logger.trace("Download progress: \(progress) for task: \(downloadTask.taskIdentifier)")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }

        logger.error("Download task completed with error: \(error.localizedDescription)")

        if let downloadTask = task as? URLSessionDownloadTask,
           let downloadJob = activeJobs[downloadTask.taskIdentifier],
           let downloadTaskIndex = downloads.firstIndex(where: { $0.taskID == downloadJob.taskID })
        {

            let swiftfinDownloadTask = downloads[downloadTaskIndex]

            // Check if we should retry
            if swiftfinDownloadTask.shouldRetry(for: error) {
                logger
                    .info(
                        "Retrying download for: \(swiftfinDownloadTask.item.displayTitle) (attempt \(swiftfinDownloadTask.retryCount + 1))"
                    )

                swiftfinDownloadTask.incrementRetryCount()

                // Exponential backoff: 2^retryCount seconds
                let delay = pow(2.0, Double(swiftfinDownloadTask.retryCount))

                DispatchQueue.global().asyncAfter(deadline: .now() + delay) {
                    self.retrySpecificDownload(for: swiftfinDownloadTask, jobType: downloadJob.type)
                }

                // Clean up current active job
                activeJobs.removeValue(forKey: downloadTask.taskIdentifier)

            } else {
                DispatchQueue.main.async {
                    self.downloads[downloadTaskIndex].state = .error(error)
                }

                // Clean up active job
                activeJobs.removeValue(forKey: downloadTask.taskIdentifier)
            }
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        logger.trace("Background URLSession did finish events")

        DispatchQueue.main.async {
            // TODO: Call completion handler for background app refresh
        }
    }

    // MARK: Helper method to move downloaded file

    private func moveDownloadedFile(
        from tempLocation: URL,
        for downloadTask: DownloadTask,
        with response: URLResponse?,
        jobType: DownloadJobType
    ) throws {
        guard let downloadFolder = downloadTask.item.downloadFolder else {
            throw DownloadTask.DownloadError.notEnoughStorage
        }

        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)

        var finalDestination: URL

        switch jobType {
        case .media:
            finalDestination = try createMediaFileDestination(
                downloadTask: downloadTask,
                response: response,
                downloadFolder: downloadFolder
            )

        case .backdropImage, .primaryImage:
            finalDestination = try createImageFileDestination(
                downloadTask: downloadTask,
                response: response,
                downloadFolder: downloadFolder,
                jobType: jobType
            )

        case .metadata:
            // Metadata is handled separately, not moved from temp location
            return

        case .subtitle:
            // TODO: Implement subtitle file destination creation
            throw DownloadTask.DownloadError.notEnoughStorage
        }

        // Move file atomically
        try FileManager.default.moveItem(at: tempLocation, to: finalDestination)

        // Set file protection and exclude from backup
        var resourceValues = URLResourceValues()
        resourceValues.isExcludedFromBackup = true
        try finalDestination.setResourceValues(resourceValues)

        logger.trace("Moved \(jobType) file to: \(finalDestination.path)")
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
            // For episodes: Downloads/[itemId]/Season-[season]/[episodeId]-[versionId].ext
            let seasonFolder = downloadFolder.appendingPathComponent("Season-\(season)")
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
        jobType: DownloadJobType
    ) throws -> URL {
        let imagesFolder = downloadFolder.appendingPathComponent("Images")
        try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)

        let filename: String
        if let httpResponse = response as? HTTPURLResponse,
           let suggestedFilename = httpResponse.suggestedFilename
        {
            filename = suggestedFilename
        } else {
            let imageExtension = (response as? HTTPURLResponse)?.mimeSubtype ?? "png"
            let prefix = jobType == .backdropImage ? "Backdrop" : "Primary"
            filename = "\(prefix).\(imageExtension)"
        }

        return imagesFolder.appendingPathComponent(filename)
    }

    private func saveMetadata(for downloadTask: DownloadTask, at folder: URL) throws {
        let metadataFile = folder.appendingPathComponent("metadata.json")

        var metadata: [String: Any] = [:]

        // Load existing metadata if it exists
        if FileManager.default.fileExists(atPath: metadataFile.path),
           let existingData = FileManager.default.contents(atPath: metadataFile.path),
           let existingMetadata = try? JSONSerialization.jsonObject(with: existingData) as? [String: Any]
        {
            metadata = existingMetadata
        }

        // Create version entry
        let versionId = downloadTask.versionId ?? "default"
        let versionMetadata: [String: Any] = [
            "versionId": versionId,
            "container": downloadTask.container,
            "isStatic": downloadTask.isStatic,
            "mediaSourceId": downloadTask.mediaSourceId as Any,
            "downloadDate": ISO8601DateFormatter().string(from: Date()),
            "taskId": downloadTask.taskID.uuidString,
        ]

        // Add version to metadata
        var versions = metadata["versions"] as? [[String: Any]] ?? []

        // Remove existing version with same ID if it exists
        versions.removeAll { version in
            (version["versionId"] as? String) == versionId
        }

        // Add new version
        versions.append(versionMetadata)
        metadata["versions"] = versions

        // Add item metadata
        metadata["itemId"] = downloadTask.item.id
        metadata["itemType"] = downloadTask.item.type?.rawValue
        metadata["displayTitle"] = downloadTask.item.displayTitle

        // Save metadata
        let jsonData = try JSONSerialization.data(withJSONObject: metadata, options: .prettyPrinted)
        try jsonData.write(to: metadataFile)

        logger.trace("Updated metadata.json for: \(downloadTask.item.displayTitle)")
    }

    private func saveAllMetadata(for downloadTask: DownloadTask) throws {
        guard let downloadFolder = downloadTask.item.downloadFolder else { return }

        // Save the new versioned metadata.json
        try saveMetadata(for: downloadTask, at: downloadFolder)

        // Save the original Item.json for backward compatibility
        let metadataFolder = downloadFolder.appendingPathComponent("Metadata")
        try FileManager.default.createDirectory(at: metadataFolder, withIntermediateDirectories: true)

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let itemJsonData = try jsonEncoder.encode(downloadTask.item)
        let itemJson = String(data: itemJsonData, encoding: .utf8)
        let itemFileURL = metadataFolder.appendingPathComponent("Item.json")

        try itemJson?.write(to: itemFileURL, atomically: true, encoding: .utf8)

        logger.trace("Saved all metadata for: \(downloadTask.item.displayTitle)")
    }

    private func retrySpecificDownload(for downloadTask: DownloadTask, jobType: DownloadJobType) {
        switch jobType {
        case .media:
            retryMediaDownload(for: downloadTask)
        case .backdropImage, .primaryImage:
            retryImageDownload(for: downloadTask, imageType: jobType)
        case .metadata:
            // Metadata doesn't need retry, just regenerate
            do {
                try saveAllMetadata(for: downloadTask)
                markJobCompleted(taskID: downloadTask.taskID, jobType: .metadata)
            } catch {
                logger.error("Failed to save metadata on retry: \(error.localizedDescription)")
            }
        case .subtitle:
            // TODO: Implement subtitle retry
            break
        }
    }

    private func retryMediaDownload(for downloadTask: DownloadTask) {
        guard let downloadURL = constructMediaURL(
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

        Task {
            do {
                try await startSpecificDownload(for: downloadTask, jobType: .media, url: downloadURL)
            } catch {
                logger.error("Failed to retry media download: \(error.localizedDescription)")
            }
        }
    }

    private func retryImageDownload(for downloadTask: DownloadTask, imageType: DownloadJobType) {
        guard let imageURL = createImageDownloadURL(for: downloadTask.item, imageType: imageType) else {
            logger.error("Failed to create image URL for retry")
            return
        }

        Task {
            do {
                try await startSpecificDownload(for: downloadTask, jobType: imageType, url: imageURL)
            } catch {
                logger.error("Failed to retry image download: \(error.localizedDescription)")
            }
        }
    }
}

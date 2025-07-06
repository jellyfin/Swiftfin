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
import Get
import JellyfinAPI
import Logging

// TODO: Only move items if entire download successful
// TODO: Better state for which stage of downloading

class DownloadTask: NSObject, ObservableObject {

    // MARK: - Types

    enum DownloadError: Error {

        case notEnoughStorage

        var localizedDescription: String {
            switch self {
            case .notEnoughStorage:
                return "Not enough storage"
            }
        }
    }

    enum State {

        case cancelled
        case complete
        case downloading(Double)
        case error(Error)
        case ready
    }

    // MARK: - Properties

    private let logger = Logger.swiftfin()
    @Injected(\.currentUserSession)
    private var userSession: UserSession!

    @Published
    var state: State = .ready {
        didSet {
            // Notify DownloadManager when state changes for UI updates
            notifyDownloadManager()
        }
    }

    private var downloadTask: Task<Void, Never>?

    let item: BaseItemDto

    var imagesFolder: URL? {
        item.downloadFolder?.appendingPathComponent("Images")
    }

    var metadataFolder: URL? {
        item.downloadFolder?.appendingPathComponent("Metadata")
    }

    // MARK: - Initialization

    init(item: BaseItemDto) {
        let logger = Logger.swiftfin()
        logger.debug("Creating DownloadTask for item: \(item.displayTitle)")
        logger.debug("Item ID: \(item.id ?? "nil")")
        logger.debug("Item type: \(item.type?.rawValue ?? "nil")")
        logger.debug("Item download folder: \(item.downloadFolder?.path ?? "nil")")

        self.item = item
    }

    // MARK: - Public API

    func createFolder() throws {
        guard let downloadFolder = item.downloadFolder else { return }
        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)
    }

    func download() {
        logger.info("Starting download process for item: \(item.displayTitle) (ID: \(item.id ?? "unknown"))")
        logger.debug("Initial state: \(state)")
        logger.debug("Download folder: \(item.downloadFolder?.path ?? "nil")")

        let task = Task {
            logger.debug("Download task started on background thread")

            // Check available storage before starting download
            #if os(iOS)
            if let fileSize = item.mediaSources?.first?.size,
               fileSize > 0
            {
                let availableStorage = FileManager.default.availableStorage
                let requiredSpace = Int(Double(fileSize) * 1.2) // Add 20% buffer for temporary files

                logger.debug("File size: \(fileSize), Available storage: \(availableStorage), Required space: \(requiredSpace)")

                if availableStorage < requiredSpace {
                    logger.error("Insufficient storage for download. Available: \(availableStorage), Required: \(requiredSpace)")
                    await MainActor.run {
                        self.state = .error(DownloadError.notEnoughStorage)
                        Container.shared.downloadManager().remove(task: self)
                    }
                    return
                } else {
                    logger.debug("Storage check passed")
                }
            } else {
                logger.debug("No file size information available, skipping storage check")
            }
            #endif

            // Don't delete the folder before download - we handle directory creation in downloadMedia()
            // deleteRootFolder()

            // TODO: Look at TaskGroup for parallel calls
            do {
                logger.debug("Starting media download")

                // Special handling for Series - they don't have media to download, just create folder structure
                if item.type == .series {
                    logger.info("Processing series download - creating folder structure for '\(item.displayTitle)'")

                    if let mediaSources = item.mediaSources, !mediaSources.isEmpty {
                        logger.info("Series has media sources, proceeding with download")
                        try await downloadMedia()
                    } else {
                        logger.info("Series has no media sources, creating folder structure only")
                        try createFolder()

                        // Save series metadata
                        saveMetadata()

                        // Download series images
                        await downloadPrimaryImage()
                        await downloadBackdropImage()

                        logger.info("Series folder structure created successfully")
                        await MainActor.run {
                            self.state = .complete
                        }
                        return
                    }
                } else {
                    try await downloadMedia()
                }

                logger.debug("Media download completed successfully")
            } catch {
                logger.error("Media download failed: \(error.localizedDescription)")
                await MainActor.run {
                    self.state = .error(error)
                    Container.shared.downloadManager().remove(task: self)
                }
                return
            }

            logger.debug("Starting backdrop image download")
            await downloadBackdropImage()
            logger.debug("Backdrop image download completed")

            logger.debug("Starting primary image download")
            await downloadPrimaryImage()
            logger.debug("Primary image download completed")

            logger.debug("Saving metadata")
            saveMetadata()
            logger.debug("Metadata saved successfully")

            await MainActor.run {
                logger.info("Download completed successfully for item: \(self.item.displayTitle)")
                self.state = .complete
            }
        }

        self.downloadTask = task
        logger.debug("Download task assigned to instance variable")
    }

    func cancel() {
        logger.info("Cancelling download for item: \(item.displayTitle) (ID: \(item.id ?? "unknown"))")
        logger.debug("Current state before cancellation: \(state)")

        // Cancel the underlying download task
        if let downloadTask = self.downloadTask {
            logger.debug("Cancelling underlying download task")
            downloadTask.cancel()
        } else {
            logger.debug("No underlying download task to cancel")
        }

        // Clean up any partial downloads
        logger.debug("Cleaning up partial downloads")
        deleteRootFolder()

        // Update state to cancelled
        self.state = .cancelled
        logger.debug("State updated to cancelled")

        // Remove from download manager
        logger.debug("Removing task from download manager")
        Container.shared.downloadManager().remove(task: self)

        logger.info("Download cancelled successfully for: \(item.displayTitle)")
    }

    // MARK: - File Management

    func deleteRootFolder() {
        guard let downloadFolder = item.downloadFolder else {
            logger.debug("No download folder to delete")
            return
        }

        logger.debug("Deleting root folder: \(downloadFolder)")

        do {
            try FileManager.default.removeItem(at: downloadFolder)
            logger.debug("Successfully deleted download folder")
        } catch {
            logger.error("Failed to delete download folder: \(error.localizedDescription)")
        }
    }

    func encodeMetadata() -> Data {
        try! JSONEncoder().encode(item)
    }

    // MARK: - Download Implementation

    private func downloadMedia() async throws {

        let logger = Logger.swiftfin()
        logger.info("Starting media download for item: \(item.id ?? "unknown")")

        let client = APIClient(
            baseURL: Container.shared.currentUserSession()!.client.configuration.url,
            apiKey: Container.shared.currentUserSession()!.client.accessToken ?? "",
            userId: Container.shared.currentUserSession()!.user.id
        )

        // Ensure download directory exists
        guard let downloadFolder = item.downloadFolder else {
            logger.error("No download folder available for item")
            throw JellyfinAPIError("No download folder available")
        }

        // Create base Downloads directory if it doesn't exist
        let downloadsRoot = URL.downloads
        do {
            try FileManager.default.createDirectory(at: downloadsRoot, withIntermediateDirectories: true, attributes: nil)
            logger.debug("Created base downloads directory at: \(downloadsRoot)")
        } catch {
            logger.error("Failed to create base downloads directory: \(error)")
            throw error
        }

        // Create item-specific directory
        do {
            try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true, attributes: nil)
            logger.debug("Created item download directory at: \(downloadFolder)")
        } catch {
            logger.error("Failed to create item download directory: \(error)")
            throw error
        }

        return try await withCheckedThrowingContinuation { continuation in
            client.downloadItem(
                itemId: item.id ?? "",
                destinationURL: downloadFolder.appendingPathComponent("Media"),
                onProgress: { progress in
                    Task { @MainActor in
                        self.state = .downloading(progress)
                    }
                },
                completion: { result in
                    switch result {
                    case let .success(finalURL):
                        logger.info("Media download completed successfully for item: \(self.item.id ?? "unknown") at: \(finalURL)")

                        // Save the actual filename for later retrieval
                        let actualFilename = finalURL.lastPathComponent
                        if actualFilename != "Media" {
                            // Store the actual filename in metadata for later use
                            UserDefaults.standard.set(actualFilename, forKey: "download_\(self.item.id ?? "")_filename")
                        }

                        continuation.resume()
                    case let .failure(error):
                        logger.error("Media download failed for item: \(self.item.id ?? "unknown") - \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            )
        }
    }

    private func downloadBackdropImage() async {

        guard let type = item.type else { return }

        let imageURL: URL

        // TODO: move to BaseItemDto
        switch type {
        case .movie, .series:
            guard let url = item.imageSource(.backdrop, maxWidth: 600).url else { return }
            imageURL = url
        case .episode:
            guard let url = item.imageSource(.primary, maxWidth: 600).url else { return }
            imageURL = url
        default:
            return
        }

        guard let response = try? await userSession.client.download(
            for: .init(url: imageURL).withResponse(URL.self),
            delegate: self
        ) else { return }

        let filename = getImageFilename(from: response, secondary: "Backdrop")
        saveImage(from: response, filename: filename)
    }

    // MARK: - Image Downloads

    private func downloadPrimaryImage() async {

        guard let type = item.type else { return }

        let imageURL: URL

        switch type {
        case .movie, .series:
            guard let url = item.imageSource(.primary, maxWidth: 300).url else { return }
            imageURL = url
        default:
            return
        }

        guard let response = try? await userSession.client.download(
            for: .init(url: imageURL).withResponse(URL.self),
            delegate: self
        ) else { return }

        let filename = getImageFilename(from: response, secondary: "Primary")
        saveImage(from: response, filename: filename)
    }

    private func saveImage(from response: Response<URL>?, filename: String) {

        guard let response, let imagesFolder else { return }

        do {
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)

            try FileManager.default.moveItem(
                at: response.value,
                to: imagesFolder.appendingPathComponent(filename)
            )
        } catch {
            logger.error("Error saving image: \(error.localizedDescription)")
        }
    }

    private func getImageFilename(from response: Response<URL>, secondary: String) -> String {

        if let suggestedFilename = response.response.suggestedFilename {
            return suggestedFilename
        } else {
            let imageExtension = response.response.mimeSubtype ?? "png"
            return "\(secondary).\(imageExtension)"
        }
    }

    private func saveMetadata() {
        guard let metadataFolder else { return }

        let jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted

        let itemJsonData = try! jsonEncoder.encode(item)
        let itemJson = String(data: itemJsonData, encoding: .utf8)
        let itemFileURL = metadataFolder.appendingPathComponent("Item.json")

        do {
            try FileManager.default.createDirectory(at: metadataFolder, withIntermediateDirectories: true)

            try itemJson?.write(to: itemFileURL, atomically: true, encoding: .utf8)
        } catch {
            logger.error("Error saving item metadata: \(error.localizedDescription)")
        }
    }

    // MARK: - File Access

    func getImageURL(name: String) -> URL? {
        do {
            guard let imagesFolder else { return nil }
            let images = try FileManager.default.contentsOfDirectory(atPath: imagesFolder.path)

            guard let imageFilename = images.first(where: { $0.starts(with: name) }) else { return nil }

            return imagesFolder.appendingPathComponent(imageFilename)
        } catch {
            return nil
        }
    }

    func getMediaURL() -> URL? {
        do {
            guard let downloadFolder = item.downloadFolder else {
                logger.error("No download folder available for item: \(item.id ?? "unknown")")
                return nil
            }

            let contents = try FileManager.default.contentsOfDirectory(atPath: downloadFolder.path)
            logger.debug("Download folder contents: \(contents)")

            // First check if we have a stored filename from the download
            var mediaFilename: String?
            if let storedFilename = UserDefaults.standard.string(forKey: "download_\(item.id ?? "")_filename") {
                // Verify the stored filename still exists
                if contents.contains(storedFilename) {
                    mediaFilename = storedFilename
                    logger.debug("Using stored media filename: \(storedFilename)")
                }
            }

            // If no stored filename or it doesn't exist, look for files starting with "Media"
            if mediaFilename == nil {
                mediaFilename = contents.first(where: { $0.starts(with: "Media") })
            }

            // If still no media file found, look for common video extensions
            if mediaFilename == nil {
                let videoExtensions = ["mp4", "mkv", "mov", "avi", "m4v", "webm", "ogv", "wmv", "flv", "ts", "m2ts"]
                mediaFilename = contents.first { filename in
                    let lowercased = filename.lowercased()
                    return videoExtensions.contains { lowercased.hasSuffix(".\($0)") }
                }

                if let foundFilename = mediaFilename {
                    logger.debug("Found video file by extension: \(foundFilename)")
                    let fileExtension = URL(fileURLWithPath: foundFilename).pathExtension.lowercased()
                    logger.debug("Media file format: \(fileExtension)")

                    // Log warnings for formats that may have compatibility issues
                    switch fileExtension {
                    case "avi":
                        logger.warning("AVI format detected - may require VLC player for optimal compatibility")
                    case "mkv":
                        logger.info("MKV format detected - VLC player recommended for full feature support")
                    case "wmv", "flv":
                        logger.warning("Legacy format detected (\(fileExtension)) - compatibility may vary")
                    default:
                        logger.debug("Standard format detected (\(fileExtension))")
                    }
                }
            }

            guard let foundFilename = mediaFilename else {
                logger.error("No media file found in download folder for item: \(item.id ?? "unknown")")
                logger.error("Searched for: stored filename, files starting with 'Media', and common video extensions")
                return nil
            }

            let mediaURL = downloadFolder.appendingPathComponent(foundFilename)

            // Verify the file actually exists
            guard FileManager.default.fileExists(atPath: mediaURL.path) else {
                logger.error("Media file path exists in directory listing but file doesn't exist: \(mediaURL)")
                return nil
            }

            // Validate media file properties
            do {
                let attributes = try FileManager.default.attributesOfItem(atPath: mediaURL.path)
                if let fileSize = attributes[.size] as? Int64 {
                    logger.debug("Media file size: \(fileSize) bytes")

                    // Check for minimum file size (1MB threshold to catch corrupted downloads)
                    if fileSize < 1024 * 1024 {
                        logger.warning("Media file seems very small (\(fileSize) bytes) - may be corrupted")
                    }
                } else {
                    logger.warning("Could not determine media file size")
                }

                // Check if file is readable
                guard FileManager.default.isReadableFile(atPath: mediaURL.path) else {
                    logger.error("Media file is not readable: \(mediaURL.path)")
                    return nil
                }
            } catch {
                logger.error("Error checking media file attributes: \(error)")
                return nil
            }

            logger.debug("Found and validated media file: \(mediaURL)")
            return mediaURL
        } catch {
            logger.error("Error reading download folder for item: \(item.id ?? "unknown") - \(error)")
            return nil
        }
    }

    // MARK: - DownloadManager Notification

    private func notifyDownloadManager() {
        // Notify on main thread to trigger UI updates
        DispatchQueue.main.async {
            Container.shared.downloadManager().objectWillChange.send()
        }
    }
}

extension DownloadTask: Identifiable {

    var id: String {
        item.id!
    }
}

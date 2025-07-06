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

    private let logger = Logger.swiftfin()
    @Injected(\.currentUserSession)
    private var userSession: UserSession!

    @Published
    var state: State = .ready

    private var downloadTask: Task<Void, Never>?

    let item: BaseItemDto

    var imagesFolder: URL? {
        item.downloadFolder?.appendingPathComponent("Images")
    }

    var metadataFolder: URL? {
        item.downloadFolder?.appendingPathComponent("Metadata")
    }

    init(item: BaseItemDto) {
        self.item = item
    }

    func createFolder() throws {
        guard let downloadFolder = item.downloadFolder else { return }
        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)
    }

    func download() {

        let task = Task {

            // Check available storage before starting download
            #if os(iOS)
            if let fileSize = item.mediaSources?.first?.size,
               fileSize > 0
            {
                let availableStorage = FileManager.default.availableStorage
                let requiredSpace = Int(Double(fileSize) * 1.2) // Add 20% buffer for temporary files

                if availableStorage < requiredSpace {
                    await MainActor.run {
                        self.state = .error(DownloadError.notEnoughStorage)
                        Container.shared.downloadManager().remove(task: self)
                    }
                    return
                }
            }
            #endif

            // Don't delete the folder before download - we handle directory creation in downloadMedia()
            // deleteRootFolder()

            // TODO: Look at TaskGroup for parallel calls
            do {
                try await downloadMedia()
            } catch {
                await MainActor.run {
                    self.state = .error(error)

                    Container.shared.downloadManager().remove(task: self)
                }
                return
            }
            await downloadBackdropImage()
            await downloadPrimaryImage()

            saveMetadata()

            await MainActor.run {
                self.state = .complete
            }
        }

        self.downloadTask = task
    }

    func cancel() {
        self.downloadTask?.cancel()
        self.state = .cancelled

        logger.trace("Cancelled download for: \(item.displayTitle)")
    }

    func deleteRootFolder() {
        guard let downloadFolder = item.downloadFolder else { return }
        try? FileManager.default.removeItem(at: downloadFolder)
    }

    func encodeMetadata() -> Data {
        try! JSONEncoder().encode(item)
    }

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

                if mediaFilename != nil {
                    logger.debug("Found video file by extension: \(mediaFilename!)")
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

            logger.debug("Found media file: \(mediaURL)")
            return mediaURL
        } catch {
            logger.error("Error reading download folder for item: \(item.id ?? "unknown") - \(error)")
            return nil
        }
    }
}

// MARK: URLSessionDownloadDelegate

extension DownloadTask: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        DispatchQueue.main.async {
            self.state = .downloading(progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {}

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        guard let error else { return }

        DispatchQueue.main.async {
            self.state = .error(error)

            Container.shared.downloadManager().remove(task: self)
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error else { return }

        DispatchQueue.main.async {
            self.state = .error(error)

            Container.shared.downloadManager().remove(task: self)
        }
    }
}

extension DownloadTask: Identifiable {

    var id: String {
        item.id!
    }
}

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

enum VideoQuality: String {
    case original = "Original"
    case hd = "HD"
    case sd = "SD"
}

class APIClient: NSObject {
    let baseURL: URL
    let apiKey: String
    let userId: String

    private let logger = Logger.swiftfin()
    private var downloadTasks: [URLSessionDownloadTask: (
        progress: (Double) -> Void,
        completion: (Result<URL, Error>) -> Void,
        destinationURL: URL
    )] = [:]

    init(baseURL: URL, apiKey: String, userId: String) {
        self.baseURL = baseURL
        self.apiKey = apiKey
        self.userId = userId
        super.init()
    }

    enum DownloadError: Error {
        case invalidURL
        case httpError(Int)
        case noMediaSource

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid URL"
            case let .httpError(code):
                return "HTTP Error: \(code)"
            case .noMediaSource:
                return "No media source available"
            }
        }
    }

    func downloadItem(
        itemId: String,
        destinationURL: URL,
        quality: VideoQuality = .original,
        onProgress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        logger.info("Starting download for item: \(itemId)")

        Task {
            do {
                // Get the item's media source info
                guard let userSession = Container.shared.currentUserSession() else {
                    logger.error("No user session available")
                    completion(.failure(DownloadError.invalidURL))
                    return
                }

                let client = userSession.client

                // Get item details to find the media source
                let itemRequest = Paths.getItem(itemID: itemId, userID: userId)
                let itemResponse = try await client.send(itemRequest)
                let item = itemResponse.value

                guard let mediaSource = item.mediaSources?.first else {
                    logger.error("No media source found for item: \(itemId)")
                    completion(.failure(DownloadError.noMediaSource))
                    return
                }

                // Create stream URL using the same pattern as the video player
                let videoStreamParameters = Paths.GetVideoStreamParameters(
                    isStatic: true,
                    tag: item.etag,
                    mediaSourceID: mediaSource.id
                )

                let videoStreamRequest = Paths.getVideoStream(
                    itemID: itemId,
                    parameters: videoStreamParameters
                )

                guard let streamURL = client.fullURL(with: videoStreamRequest) else {
                    logger.error("Failed to create stream URL for item: \(itemId)")
                    completion(.failure(DownloadError.invalidURL))
                    return
                }

                logger.info("Stream URL created: \(streamURL)")

                // Create download task
                let sessionConfig = URLSessionConfiguration.default
                sessionConfig.timeoutIntervalForRequest = 60.0
                sessionConfig.timeoutIntervalForResource = 300.0

                let session = URLSession(
                    configuration: sessionConfig,
                    delegate: self,
                    delegateQueue: nil
                )

                let downloadTask = session.downloadTask(with: streamURL)
                downloadTasks[downloadTask] = (onProgress, completion, destinationURL)

                logger.info("Starting download task for item: \(itemId)")
                downloadTask.resume()

            } catch {
                logger.error("Failed to prepare download for item: \(itemId) - \(error)")
                completion(.failure(error))
            }
        }
    }
}

// MARK: - URLSessionDownloadDelegate

extension APIClient: URLSessionDownloadDelegate {

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {

        guard let (onProgress, _, _) = downloadTasks[downloadTask] else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            onProgress(progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        guard let (_, completion, destinationURL) = downloadTasks[downloadTask] else { return }

        // Check response status
        if let httpResponse = downloadTask.response as? HTTPURLResponse {
            if httpResponse.statusCode != 200 {
                logger.error("HTTP Error: \(httpResponse.statusCode)")
                DispatchQueue.main.async {
                    completion(.failure(DownloadError.httpError(httpResponse.statusCode)))
                }
                downloadTasks.removeValue(forKey: downloadTask)
                return
            }
        }

        logger.info("Download completed successfully, temporary location: \(location)")

        // Extract file extension from the response
        var finalDestinationURL = destinationURL

        // Try to get filename from Content-Disposition header or URL
        if let httpResponse = downloadTask.response as? HTTPURLResponse {
            var fileExtension: String?

            // First try to get from Content-Disposition header
            if let contentDisposition = httpResponse.allHeaderFields["Content-Disposition"] as? String {
                // Parse filename from Content-Disposition header
                let components = contentDisposition.components(separatedBy: ";")
                for component in components {
                    let trimmed = component.trimmingCharacters(in: .whitespaces)
                    if trimmed.hasPrefix("filename=") {
                        var filename = trimmed.replacingOccurrences(of: "filename=", with: "")
                        filename = filename.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                        if let ext = filename.components(separatedBy: ".").last, !ext.isEmpty {
                            fileExtension = ext
                            logger.debug("Got file extension from Content-Disposition: \(ext)")
                        }
                        break
                    }
                }
            }

            // If no extension from Content-Disposition, try Content-Type
            if fileExtension == nil, let contentType = httpResponse.mimeType {
                let mimeToExtension: [String: String] = [
                    "video/mp4": "mp4",
                    "video/x-matroska": "mkv",
                    "video/webm": "webm",
                    "video/quicktime": "mov",
                    "video/x-msvideo": "avi",
                    "video/mpeg": "mpeg",
                    "video/ogg": "ogv",
                    "video/3gpp": "3gp",
                    "video/x-flv": "flv",
                    "video/x-ms-wmv": "wmv",
                    "application/x-mpegURL": "m3u8",
                    "application/vnd.apple.mpegurl": "m3u8",
                ]

                if let ext = mimeToExtension[contentType] {
                    fileExtension = ext
                    logger.debug("Got file extension from Content-Type: \(ext)")
                }
            }

            // If still no extension, try to get from the URL
            if fileExtension == nil, let url = downloadTask.originalRequest?.url {
                let pathExtension = url.pathExtension
                if !pathExtension.isEmpty {
                    fileExtension = pathExtension
                    logger.debug("Got file extension from URL: \(pathExtension)")
                }
            }

            // Apply the extension to the destination URL if found
            if let ext = fileExtension, !ext.isEmpty {
                let destinationWithoutExtension = destinationURL.deletingPathExtension()
                finalDestinationURL = destinationWithoutExtension.appendingPathExtension(ext)
                logger.info("Final destination URL with extension: \(finalDestinationURL)")
            } else {
                logger.warning("Could not determine file extension, saving without extension")
            }
        }

        // Move the file from temporary location to destination
        do {
            // Create destination directory if it doesn't exist
            let destinationDirectory = finalDestinationURL.deletingLastPathComponent()
            try FileManager.default.createDirectory(
                at: destinationDirectory,
                withIntermediateDirectories: true,
                attributes: nil
            )

            // Remove existing file if it exists
            if FileManager.default.fileExists(atPath: finalDestinationURL.path) {
                try FileManager.default.removeItem(at: finalDestinationURL)
            }

            // Move the downloaded file
            try FileManager.default.moveItem(at: location, to: finalDestinationURL)

            logger.info("Successfully moved downloaded file to: \(finalDestinationURL)")
            DispatchQueue.main.async {
                completion(.success(finalDestinationURL))
            }
        } catch {
            logger.error("Failed to move downloaded file: \(error)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }

        downloadTasks.removeValue(forKey: downloadTask)
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {

        guard let downloadTask = task as? URLSessionDownloadTask,
              let (_, completion, _) = downloadTasks[downloadTask] else { return }

        if let error = error {
            logger.error("Download failed with error: \(error)")
            DispatchQueue.main.async {
                completion(.failure(error))
            }
        }

        downloadTasks.removeValue(forKey: downloadTask)
    }
}

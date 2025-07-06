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
        destinationURL: URL,
        itemId: String,
        retryCount: Int
    )] = [:]

    // Store resume data for failed downloads
    private var resumeData: [String: Data] = [:]
    private let maxRetries = 3

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
        case timeoutAfterRetries(Int)
        case networkConnectionLost
        case insufficientStorage
        case fileSystemError(String)

        var localizedDescription: String {
            switch self {
            case .invalidURL:
                return "Invalid download URL"
            case let .httpError(code):
                return "Server error (\(code)). Please try again later."
            case .noMediaSource:
                return "No media source available for download"
            case let .timeoutAfterRetries(retries):
                return "Download timed out after \(retries) attempts. Check your network connection and try again."
            case .networkConnectionLost:
                return "Network connection lost. Please check your internet connection and try again."
            case .insufficientStorage:
                return "Not enough storage space available to download this item."
            case let .fileSystemError(details):
                return "File system error: \(details)"
            }
        }

        var userFriendlyMessage: String {
            switch self {
            case .invalidURL:
                return "There was a problem with the download link. Please try refreshing and downloading again."
            case let .httpError(code):
                return "The server returned an error (\(code)). This usually resolves itself - please try again in a few minutes."
            case .noMediaSource:
                return "This content cannot be downloaded. It may not be available for offline viewing."
            case let .timeoutAfterRetries(retries):
                return "The download is taking too long, possibly due to a slow connection or large file size. The download was attempted \(retries) times. Try downloading during off-peak hours or check your network connection."
            case .networkConnectionLost:
                return "Your internet connection was interrupted. Please reconnect and try downloading again. Downloads can be resumed from where they left off."
            case .insufficientStorage:
                return "You don't have enough free space to download this content. Please delete some files or apps and try again."
            case let .fileSystemError(details):
                return "There was a problem accessing your device's storage: \(details). Please restart the app and try again."
            }
        }

        var isRetryable: Bool {
            switch self {
            case .invalidURL, .httpError, .timeoutAfterRetries, .networkConnectionLost, .fileSystemError:
                return true
            case .noMediaSource, .insufficientStorage:
                return false
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

                // Create background download session with unique identifier
                let sessionIdentifier = "bg-download-\(itemId)"
                let sessionConfig = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
                sessionConfig.timeoutIntervalForRequest = 120.0 // 2 minutes for initial response
                sessionConfig.timeoutIntervalForResource = 7200.0 // 2 hours for complete download
                sessionConfig.allowsCellularAccess = true
                sessionConfig.waitsForConnectivity = true
                sessionConfig.networkServiceType = .background // Optimize for large downloads

                let session = URLSession(
                    configuration: sessionConfig,
                    delegate: self,
                    delegateQueue: nil
                )

                // Check if we have resume data for this item
                let downloadTask: URLSessionDownloadTask
                if let resumeDataForItem = resumeData[itemId] {
                    logger.info("Resuming download for item: \(itemId)")
                    downloadTask = session.downloadTask(withResumeData: resumeDataForItem)
                    resumeData.removeValue(forKey: itemId) // Clear resume data after use
                } else {
                    logger.info("Starting new download for item: \(itemId)")
                    downloadTask = session.downloadTask(with: streamURL)
                }

                downloadTasks[downloadTask] = (onProgress, completion, destinationURL, itemId, 0)

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

        guard let (onProgress, _, _, _, _) = downloadTasks[downloadTask] else { return }

        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        DispatchQueue.main.async {
            onProgress(progress)
        }
    }

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {

        guard let (_, completion, destinationURL, _, _) = downloadTasks[downloadTask] else { return }

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
              let (onProgress, completion, destinationURL, itemId, retryCount) = downloadTasks[downloadTask] else { return }

        if let error = error {
            logger.error("Download failed with error: \(error)")

            // Check if this is a timeout error and we have resume data
            if let nsError = error as NSError?,
               nsError.domain == NSURLErrorDomain,
               nsError.code == NSURLErrorTimedOut || nsError.code == NSURLErrorNetworkConnectionLost,
               let resumeDataForTask = nsError.userInfo[NSURLSessionDownloadTaskResumeData] as? Data,
               retryCount < maxRetries
            {

                logger
                    .info(
                        "Timeout/connection error detected for item \(itemId), saving resume data and retrying (attempt \(retryCount + 1)/\(maxRetries))"
                    )

                // Store resume data for retry
                resumeData[itemId] = resumeDataForTask

                // Clean up current task
                downloadTasks.removeValue(forKey: downloadTask)

                // Retry after a short delay with exponential backoff
                let retryDelay = pow(2.0, Double(retryCount)) // 1s, 2s, 4s delays
                DispatchQueue.main.asyncAfter(deadline: .now() + retryDelay) {
                    self.retryDownload(
                        itemId: itemId,
                        destinationURL: destinationURL,
                        retryCount: retryCount + 1,
                        onProgress: onProgress,
                        completion: completion
                    )
                }
                return
            }

            // If not retryable or max retries exceeded, fail the download
            logger.error("Download failed permanently for item \(itemId) after \(retryCount) retries")

            // Convert to more user-friendly error message
            let userFriendlyError: DownloadError
            if let nsError = error as NSError?,
               nsError.domain == NSURLErrorDomain
            {
                switch nsError.code {
                case NSURLErrorTimedOut:
                    userFriendlyError = .timeoutAfterRetries(retryCount)
                case NSURLErrorNetworkConnectionLost, NSURLErrorNotConnectedToInternet:
                    userFriendlyError = .networkConnectionLost
                default:
                    userFriendlyError = .fileSystemError(error.localizedDescription)
                }
            } else {
                userFriendlyError = .fileSystemError(error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion(.failure(userFriendlyError))
            }
        }

        downloadTasks.removeValue(forKey: downloadTask)
    }

    // MARK: - Background Session Support

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        logger.info("Background URL session finished events: \(session.configuration.identifier ?? "unknown")")

        // Call the completion handler to let the system know we're done
        if let identifier = session.configuration.identifier {
            BackgroundSessionManager.shared.callCompletionHandler(for: identifier)
        }
    }

    func urlSession(_ session: URLSession, didBecomeInvalidWithError error: Error?) {
        if let error = error {
            logger.error("URL session became invalid with error: \(error)")
        } else {
            logger.info("URL session became invalid")
        }

        // Clean up any remaining tasks for this session
        // Note: We can't directly compare sessions, so we'll remove all tasks
        // This is a limitation of URLSessionDownloadTask not exposing its session
        downloadTasks.removeAll()
    }

    private func retryDownload(
        itemId: String,
        destinationURL: URL,
        retryCount: Int,
        onProgress: @escaping (Double) -> Void,
        completion: @escaping (Result<URL, Error>) -> Void
    ) {
        logger.info("Retrying download for item: \(itemId) (attempt \(retryCount + 1))")

        Task {
            do {
                guard let userSession = Container.shared.currentUserSession() else {
                    completion(.failure(DownloadError.invalidURL))
                    return
                }

                let client = userSession.client
                let itemRequest = Paths.getItem(itemID: itemId, userID: userId)
                let itemResponse = try await client.send(itemRequest)
                let item = itemResponse.value

                guard let mediaSource = item.mediaSources?.first else {
                    completion(.failure(DownloadError.noMediaSource))
                    return
                }

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
                    completion(.failure(DownloadError.invalidURL))
                    return
                }

                // Create background download session with unique identifier
                let sessionIdentifier = "bg-download-\(itemId)"
                let sessionConfig = URLSessionConfiguration.background(withIdentifier: sessionIdentifier)
                sessionConfig.timeoutIntervalForRequest = 120.0
                sessionConfig.timeoutIntervalForResource = 7200.0
                sessionConfig.allowsCellularAccess = true
                sessionConfig.waitsForConnectivity = true
                sessionConfig.networkServiceType = .background

                let session = URLSession(
                    configuration: sessionConfig,
                    delegate: self,
                    delegateQueue: nil
                )

                // Create download task (will use resume data if available)
                let downloadTask: URLSessionDownloadTask
                if let resumeDataForItem = resumeData[itemId] {
                    logger.info("Using resume data for retry of item: \(itemId)")
                    downloadTask = session.downloadTask(withResumeData: resumeDataForItem)
                    resumeData.removeValue(forKey: itemId)
                } else {
                    downloadTask = session.downloadTask(with: streamURL)
                }

                downloadTasks[downloadTask] = (onProgress, completion, destinationURL, itemId, retryCount)
                downloadTask.resume()

            } catch {
                logger.error("Failed to retry download for item: \(itemId) - \(error)")
                completion(.failure(error))
            }
        }
    }
}

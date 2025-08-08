//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import Logging

final class DownloadSessionManager: NSObject, DownloadSessionManaging {

    private let logger = Logger.swiftfin()

    // Background URLSession infrastructure
    private var backgroundSession: URLSession!
    private let sessionQueue = DispatchQueue(label: "downloadManager.session", qos: .utility)
    private static let backgroundSessionIdentifier = "com.jellyfin.swiftfin.background-downloads"

    // Mapping between URLSessionDownloadTask identifier and DownloadJob
    private var activeJobs: [Int: DownloadJob] = [:]

    // Delegate for session events
    weak var delegate: DownloadSessionDelegate?

    override init() {
        super.init()
        setupBackgroundSession()
        recoverActiveDownloads()
    }

    // MARK: - Public Interface

    func start(url: URL, taskID: UUID, jobType: DownloadJobType) async throws {
        let urlRequest = URLRequest(url: url)
        let urlDownloadTask = backgroundSession.downloadTask(with: urlRequest)

        let downloadJob = DownloadJob(
            type: jobType,
            taskID: taskID,
            url: url,
            destinationPath: "" // Will be determined during file move
        )

        // Associate URLSessionDownloadTask with DownloadJob
        activeJobs[urlDownloadTask.taskIdentifier] = downloadJob

        urlDownloadTask.resume()

        logger.trace("Started \(jobType) download with task identifier: \(urlDownloadTask.taskIdentifier)")
    }

    func pause(taskID: UUID) {
        sessionQueue.async {
            let relatedTasks = self.activeJobs.filter { $0.value.taskID == taskID }

            for (urlTaskIdentifier, downloadJob) in relatedTasks {
                self.backgroundSession.getAllTasks { tasks in
                    if let urlTask = tasks.first(where: { $0.taskIdentifier == urlTaskIdentifier }) as? URLSessionDownloadTask {
                        urlTask.cancel { _ in
                            // The delegate will handle storing resume data if needed
                            self.logger.trace("Paused URLSession task: \(urlTaskIdentifier)")
                        }
                    }
                }

                // Remove from task mapping since task is cancelled
                self.activeJobs.removeValue(forKey: urlTaskIdentifier)
            }
        }
    }

    func resume(taskID: UUID, with resumeData: Data?) async throws {
        if let resumeData = resumeData {
            // Resume with existing data
            let urlDownloadTask = backgroundSession.downloadTask(withResumeData: resumeData)

            let downloadJob = DownloadJob(
                type: .media, // Assume media for resume - could be passed as parameter
                taskID: taskID,
                url: URL(string: "")!, // URL not needed for resume
                destinationPath: ""
            )

            activeJobs[urlDownloadTask.taskIdentifier] = downloadJob
            urlDownloadTask.resume()

            logger.trace("Resumed download task with identifier: \(urlDownloadTask.taskIdentifier)")
        } else {
            // Would need to restart from beginning - this should be handled by the coordinator
            throw NSError(domain: "DownloadSessionManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "No resume data available"])
        }
    }

    func cancel(taskID: UUID) {
        sessionQueue.async {
            let relatedTasks = self.activeJobs.filter { $0.value.taskID == taskID }

            for (urlTaskIdentifier, _) in relatedTasks {
                self.backgroundSession.getAllTasks { tasks in
                    if let urlTask = tasks.first(where: { $0.taskIdentifier == urlTaskIdentifier }) {
                        urlTask.cancel()
                        self.logger.trace("Cancelled URLSession task: \(urlTaskIdentifier)")
                    }
                }

                // Remove from task mapping
                self.activeJobs.removeValue(forKey: urlTaskIdentifier)
            }
        }
    }

    func getAllTasks() -> [URLSessionDownloadTask] {
        var tasks: [URLSessionDownloadTask] = []
        let semaphore = DispatchSemaphore(value: 0)

        backgroundSession.getAllTasks { allTasks in
            tasks = allTasks.compactMap { $0 as? URLSessionDownloadTask }
            semaphore.signal()
        }

        semaphore.wait()
        return tasks
    }

    // MARK: - Private Setup

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

    // MARK: - Helper Methods

    func getDownloadJob(for taskIdentifier: Int) -> DownloadJob? {
        activeJobs[taskIdentifier]
    }

    func removeDownloadJob(for taskIdentifier: Int) {
        activeJobs.removeValue(forKey: taskIdentifier)
    }
}

// MARK: - URLSessionDownloadDelegate

extension DownloadSessionManager: URLSessionDownloadDelegate {

    func urlSession(_ session: URLSession, downloadTask: URLSessionDownloadTask, didFinishDownloadingTo location: URL) {
        logger.trace("Download completed: \(downloadTask.taskIdentifier)")

        // Notify delegate about completion
        delegate?.sessionDidCompleteDownload(
            taskIdentifier: downloadTask.taskIdentifier,
            location: location,
            response: downloadTask.response
        )
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        // Guard against unknown content length which can be -1
        guard totalBytesExpectedToWrite > 0 else { return }
        let progress = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)

        // Notify delegate about progress
        delegate?.sessionDidUpdateProgress(
            taskIdentifier: downloadTask.taskIdentifier,
            progress: progress
        )

        logger.trace("Download progress: \(progress) for task: \(downloadTask.taskIdentifier)")
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let error = error else { return }

        logger.error("Download task completed with error: \(error.localizedDescription)")

        if let downloadTask = task as? URLSessionDownloadTask {
            // Notify delegate about error
            delegate?.sessionDidCompleteWithError(
                taskIdentifier: downloadTask.taskIdentifier,
                error: error
            )
        }
    }

    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        logger.trace("Background URLSession did finish events")

        // Notify delegate about background events completion
        delegate?.sessionDidFinishBackgroundEvents()
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// `URLSessionDownloadDelegate` routing. The manager hosts the background
/// `URLSession` (only one delegate is allowed), and these callbacks dispatch
/// each event back to the matching `DownloadTask` for the per-download work.
extension DownloadManager: URLSessionDownloadDelegate {

    /// Called by iOS after it has finished delivering all queued events for a
    /// background `URLSession`. We invoke the completion handler stashed by
    /// the AppDelegate so iOS knows it can re-suspend the app.
    func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        DispatchQueue.main.async {
            guard let identifier = session.configuration.identifier else { return }
            if let handler = Self.backgroundCompletionHandlers.removeValue(forKey: identifier) {
                handler()
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let taskID = downloadTask.taskDescription else { return }

        DispatchQueue.main.async {
            self.update(id: taskID, throttlePersist: true) { task in
                task.bytesDownloaded = totalBytesWritten
                if totalBytesExpectedToWrite > 0 {
                    task.bytesTotal = totalBytesExpectedToWrite
                }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let taskID = downloadTask.taskDescription else { return }
        guard let task = self.task(id: taskID) else { return }
        guard let userSession else { return }

        let response = downloadTask.response

        do {
            let filename = try task.moveDownloadedMedia(from: location, response: response)

            DispatchQueue.main.async {
                self.update(id: taskID) { task in
                    task.resumeData = nil
                }
            }

            guard let item = task.item else {
                logger.error("Cannot finalize \(taskID): item JSON failed to decode")
                DispatchQueue.main.async {
                    self.update(id: taskID) { task in
                        task.state = .error(.unknown("Failed to read item metadata"))
                    }
                }
                return
            }

            Task {
                let images = await task.downloadImages(item: item)
                await task.downloadSubtitles(item: item, userSession: userSession)
                await MainActor.run {
                    self.graduate(taskID: taskID, mediaRelativePath: filename, images: images)
                }
            }
        } catch {
            logger.error("Failed to move downloaded media for \(taskID): \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.update(id: taskID) { task in
                    task.state = .error(DownloadError(error))
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskID = task.taskDescription else { return }

        DispatchQueue.main.async {
            self.activeURLTask = nil
            if self.activeTaskID == taskID { self.activeTaskID = nil }

            if let error = error as NSError? {
                if error.domain == NSURLErrorDomain, error.code == NSURLErrorCancelled {
                    if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        self.update(id: taskID) { task in
                            task.resumeData = resumeData
                            task.state = .paused
                        }
                    }
                } else {
                    self.update(id: taskID) { task in
                        task.state = .error(DownloadError(error))
                    }
                }
            }

            self.advanceQueue()
        }
    }
}

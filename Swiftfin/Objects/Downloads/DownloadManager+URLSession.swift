//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DownloadManager: URLSessionDownloadDelegate {

    nonisolated func urlSessionDidFinishEvents(forBackgroundURLSession session: URLSession) {
        let identifier = session.configuration.identifier
        MainActor.assumeIsolated {
            guard let identifier else { return }
            if let handler = Self.backgroundCompletionHandlers.removeValue(forKey: identifier) {
                handler()
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard let taskID = downloadTask.taskDescription else { return }

        MainActor.assumeIsolated {
            self.update(id: taskID, throttle: true) { task in
                task.bytesDownloaded = totalBytesWritten
                if totalBytesExpectedToWrite > 0 {
                    task.bytesTotal = totalBytesExpectedToWrite
                }
            }
        }
    }

    nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let taskID = downloadTask.taskDescription else { return }
        let response = downloadTask.response

        MainActor.assumeIsolated {
            guard let task = self.task(id: taskID) else { return }
            guard let userSession = self.userSession else { return }

            do {
                let filename = try task.moveDownloadedMedia(from: location, response: response)
                self.update(id: taskID) { $0.resumeData = nil }

                Task {
                    let item = task.item
                    let images = await task.downloadImages(item: item)
                    await task.downloadSubtitles(item: item, userSession: userSession)
                    await MainActor.run {
                        self.complete(id: taskID, mediaRelativePath: filename, images: images)
                    }
                }
            } catch {
                self.logger.error("Failed to move downloaded media for \(taskID): \(error.localizedDescription)")
                self.update(id: taskID) { $0.state = .error(DownloadError(error)) }
            }
        }
    }

    nonisolated func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let taskID = task.taskDescription else { return }
        let nsError = error as NSError?
        let resumeData = nsError?.userInfo[NSURLSessionDownloadTaskResumeData] as? Data

        MainActor.assumeIsolated {
            if self.active?.id == taskID { self.active = nil }

            if let nsError {
                if nsError.domain == NSURLErrorDomain, nsError.code == NSURLErrorCancelled {
                    if let resumeData {
                        self.update(id: taskID) { task in
                            task.resumeData = resumeData
                            task.state = .paused
                        }
                    }
                } else {
                    self.update(id: taskID) { task in
                        task.state = .error(DownloadError(nsError))
                    }
                }
            }

            self.advanceQueue()
        }
    }
}

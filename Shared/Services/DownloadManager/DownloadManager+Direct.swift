//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension DownloadManager {

    func startRawDownload(id: String, userSession: UserSession) throws -> URLSessionDownloadTask {
        let request = Paths.getDownload(itemID: id)
        guard let url = userSession.client.url(with: request, queryAPIKey: true) else {
            throw ErrorMessage("Could not build download URL for \(id)")
        }
        return urlSession.downloadTask(with: url)
    }
}

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

        let subtype = downloadTask.response?.mimeSubtype
        let ext = subtype.map { ".\($0)" } ?? ""
        let filename = "\(taskID)\(ext)"
        let downloadFolder = task.downloadFolder
        let item = task.item

        do {
            try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)
            let destination = downloadFolder.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)

            DispatchQueue.main.async {
                self.update(id: taskID) { task in
                    task.resumeData = nil
                }
            }

            guard let item else {
                logger.error("Cannot finalize \(taskID): item JSON failed to decode")
                DispatchQueue.main.async {
                    self.update(id: taskID) { task in
                        task.state = .error(.unknown("Failed to read item metadata"))
                    }
                }
                return
            }

            Task {
                let images = await downloadItemImages(taskID: taskID, item: item)
                await downloadCompanionFiles(taskID: taskID, item: item)
                try? await writeMetadataSidecar(item: item, in: downloadFolder)
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

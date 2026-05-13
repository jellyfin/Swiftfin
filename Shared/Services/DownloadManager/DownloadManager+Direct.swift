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
        guard let url = userSession.client.fullURL(with: request, queryAPIKey: true) else {
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
        guard let recordID = downloadTask.taskDescription else { return }

        DispatchQueue.main.async {
            self.update(id: recordID, throttlePersist: true) { record in
                record.bytesDownloaded = totalBytesWritten
                if totalBytesExpectedToWrite > 0 {
                    record.bytesTotal = totalBytesExpectedToWrite
                }
            }
        }
    }

    func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        guard let recordID = downloadTask.taskDescription else { return }
        guard let record = self.record(id: recordID) else { return }

        let subtype = downloadTask.response?.mimeSubtype
        let ext = subtype.map { ".\($0)" } ?? ""
        let filename = "\(recordID)\(ext)"

        do {
            try FileManager.default.createDirectory(at: record.downloadFolder, withIntermediateDirectories: true)
            let destination = record.downloadFolder.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: destination)
            try FileManager.default.moveItem(at: location, to: destination)

            DispatchQueue.main.async {
                self.update(id: recordID) { rec in
                    rec.mediaRelativePath = filename
                    rec.resumeData = nil
                }
            }

            if let item = record.item {
                Task {
                    await downloadItemImages(recordID: recordID, item: item)
                    await downloadCompanionFiles(recordID: recordID, item: item)
                    try? await writeMetadataSidecar(item: item, in: record.downloadFolder)
                }
            }
        } catch {
            logger.error("Failed to move downloaded media for \(recordID): \(error.localizedDescription)")
            DispatchQueue.main.async {
                self.update(id: recordID) { rec in
                    rec.state = .error
                }
            }
        }
    }

    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        guard let recordID = task.taskDescription else { return }

        DispatchQueue.main.async {
            self.activeURLTasks.removeValue(forKey: recordID)
            if self.activeRecordID == recordID { self.activeRecordID = nil }

            if let error = error as NSError? {
                if error.domain == NSURLErrorDomain, error.code == NSURLErrorCancelled {
                    if let resumeData = error.userInfo[NSURLSessionDownloadTaskResumeData] as? Data {
                        self.update(id: recordID) { rec in
                            rec.resumeData = resumeData
                            rec.state = .paused
                        }
                    }
                } else {
                    self.update(id: recordID) { rec in
                        rec.state = .error
                    }
                }
            } else {
                self.update(id: recordID) { rec in
                    rec.state = .complete
                }
                self.refreshCompletedItems()
            }
            self.advanceQueue()
        }
    }
}

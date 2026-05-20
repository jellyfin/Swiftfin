//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

/// Direct-source download flavor — pulls the original media file from the
/// server as-is. Per-download mechanics for this flavor live here; future
/// transcoded flavors will have their own sibling extension.
extension DownloadTask {

    /// Builds a fresh `URLSessionDownloadTask` for this download.
    /// If `resumeData` is present, the transfer resumes from the previous
    /// byte offset; otherwise a new request is issued against the
    /// `getDownload` endpoint.
    func makeURLSessionTask(in urlSession: URLSession, userSession: UserSession) throws -> URLSessionDownloadTask {
        let urlTask: URLSessionDownloadTask
        if let resumeData {
            urlTask = urlSession.downloadTask(withResumeData: resumeData)
        } else {
            let request = Paths.getDownload(itemID: id)
            guard let url = userSession.client.url(with: request, queryAPIKey: true) else {
                throw ErrorMessage("Could not build download URL for \(id)")
            }
            urlTask = urlSession.downloadTask(with: url)
        }
        urlTask.taskDescription = id
        return urlTask
    }

    /// Moves the finished temp file into the task's download folder.
    /// Returns the filename relative to `downloadFolder`.
    func moveDownloadedMedia(from location: URL, response: URLResponse?) throws -> String {
        let subtype = response?.mimeSubtype
        let ext = subtype.map { ".\($0)" } ?? ""
        let filename = "\(id)\(ext)"

        try FileManager.default.createDirectory(at: downloadFolder, withIntermediateDirectories: true)
        let destination = downloadFolder.appendingPathComponent(filename)
        try? FileManager.default.removeItem(at: destination)
        try FileManager.default.moveItem(at: location, to: destination)
        return filename
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

extension DownloadTask {

    func makeURLSessionTask(in urlSession: URLSession, userSession: UserSession) throws -> URLSessionDownloadTask {
        guard case let .media(type) = kind else {
            throw ErrorMessage("Container download has no URL session task")
        }

        let downloadTask: URLSessionDownloadTask = if let resumeData {
            urlSession.downloadTask(withResumeData: resumeData)
        } else {
            switch type {
            case .direct:
                try makeDirectURLSessionTask(in: urlSession, userSession: userSession)
            case let .transcode(bitrate):
                try makeTranscodeURLSessionTask(in: urlSession, userSession: userSession, bitrate: bitrate)
            }
        }

        downloadTask.taskDescription = id

        return downloadTask
    }

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

    // MARK: Direct Download

    private func makeDirectURLSessionTask(
        in urlSession: URLSession,
        userSession: UserSession
    ) throws -> URLSessionDownloadTask {
        guard let url = userSession.client.url(with: Paths.getDownload(itemID: id), queryAPIKey: true) else {
            throw ErrorMessage("Could not build download URL for \(id)")
        }

        return urlSession.downloadTask(with: url)
    }

    // MARK: Transcoded Download

    func makeTranscodeURLSessionTask(
        in urlSession: URLSession,
        userSession: UserSession,
        bitrate: PlaybackBitrate? = nil
    ) throws -> URLSessionDownloadTask {

        // TODO: build transcoded download URL

        let deviceProfile = DeviceProfile.build(
            for: Defaults[.VideoPlayer.videoPlayerType],
            compatibilityMode: Defaults[.VideoPlayer.Playback.compatibilityMode],
            maxBitrate: bitrate?.rawValue ?? Defaults[.VideoPlayer.Playback.appMaximumBitrate].rawValue
        )

        assertionFailure("Transcoded downloads are not yet implemented")

        throw ErrorMessage("Transcoded downloads are not yet implemented")
    }
}

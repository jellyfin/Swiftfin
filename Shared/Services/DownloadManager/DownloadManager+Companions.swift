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

    func downloadCompanionFiles(recordID: String, item: BaseItemDto) async {
        guard let userSession else { return }
        guard let record = record(id: recordID) else { return }

        let externalSubtitles = (item.mediaSources?.first?.mediaStreams ?? []).filter {
            $0.type == .subtitle && ($0.isExternal ?? false) && $0.deliveryURL != nil
        }

        guard !externalSubtitles.isEmpty else { return }

        let folder = record.downloadFolder.appendingPathComponent("Subtitles", isDirectory: true)
        try? FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)

        for stream in externalSubtitles {
            await downloadSubtitle(stream: stream, into: folder, userSession: userSession)
        }
    }

    private func downloadSubtitle(stream: MediaStream, into folder: URL, userSession: UserSession) async {
        guard let deliveryURL = stream.deliveryURL else { return }
        guard let url = userSession.client.fullURL(with: deliveryURL) else { return }

        do {
            let (data, response) = try await URLSession.shared.data(from: url)
            let ext = stream.codec?.lowercased()
                ?? response.mimeSubtype
                ?? (url.pathExtension.isEmpty ? "srt" : url.pathExtension)
            let language = stream.language ?? "und"
            let index = stream.index ?? 0
            let filename = "\(language).\(index).\(ext)"
            let destination = folder.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: destination)
            try data.write(to: destination)
        } catch {
            logger.warning("Failed to download subtitle stream \(stream.index ?? -1): \(error.localizedDescription)")
        }
    }
}

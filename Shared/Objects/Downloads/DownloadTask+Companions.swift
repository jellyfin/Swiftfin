//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import Logging

extension DownloadTask {

    func downloadImages(item: BaseItemDto) async {
        var sourceLists: [[ImageSource]] = [
            item.imageSources(for: .portrait, size: .custom(width: 600)),
            item.imageSources(for: .landscape, size: .custom(width: 800)),
            item.imageSources(for: .square, size: .custom(width: 600)),
        ]

        if item.imageTags?[ImageType.logo.rawValue] != nil {
            sourceLists.append([item.imageSource(.logo, environment: ImageSourceOptions(maxWidth: 400))])
        }

        var seen: Set<String> = []

        for sources in sourceLists {
            for source in sources {
                guard let url = source.url else { continue }
                let pathKey = url.path
                guard seen.insert(pathKey).inserted else { continue }

                await downloadImage(from: url, pathKey: pathKey)
            }
        }

        if parameters.isChaptersEnabled {
            for (index, chapter) in (item.fullChapterInfo ?? []).enumerated() {
                guard let url = chapter.imageSource.url else { continue }

                await downloadImage(
                    from: url,
                    pathKey: BaseItemDto.downloadedImagePathKey(for: url, index: index)
                )
            }
        }
    }

    private func downloadImage(from sourceURL: URL, pathKey: String) async {
        guard let filename = BaseItemDto.downloadedImageFilename(for: pathKey) else { return }

        do {
            try FileManager.default.createDirectory(at: imagesFolder, withIntermediateDirectories: true)
            let (data, _) = try await URLSession.shared.data(from: sourceURL)

            let destination = imagesFolder.appendingPathComponent(filename)
            try? FileManager.default.removeItem(at: destination)
            try data.write(to: destination)
        } catch {
            Logger.swiftfin().warning("Failed to download image \(pathKey): \(error.localizedDescription)")
        }
    }

    func downloadSubtitles(item: BaseItemDto, userSession: UserSession) async {
        let externalSubtitles = (item.mediaSources?.first?.mediaStreams ?? []).filter {
            $0.type == .subtitle && ($0.isExternal ?? false) && $0.deliveryURL != nil
        }

        guard externalSubtitles.isNotEmpty else { return }

        try? FileManager.default.createDirectory(at: subtitlesFolder, withIntermediateDirectories: true)

        for stream in externalSubtitles {
            await downloadSubtitle(stream: stream, userSession: userSession)
        }
    }

    private func downloadSubtitle(stream: MediaStream, userSession: UserSession) async {
        guard let deliveryURL = stream.deliveryURL else { return }
        guard let url = userSession.client.url(path: deliveryURL) else { return }
        guard let destination = localSubtitleURL(for: stream) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            try? FileManager.default.removeItem(at: destination)
            try data.write(to: destination)
        } catch {
            Logger.swiftfin().warning("Failed to download subtitle stream \(stream.index ?? -1): \(error.localizedDescription)")
        }
    }
}

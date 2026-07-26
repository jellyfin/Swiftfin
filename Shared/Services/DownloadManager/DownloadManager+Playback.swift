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

extension DownloadManager {

    func mediaPlayerItemProvider(for item: BaseItemDto) -> MediaPlayerItemProvider? {
        guard let task = playableTask(for: item), task.mediaURL != nil else { return nil }

        let downloadedSource = task.item.mediaSources?.first

        return MediaPlayerItemProvider(
            item: task.item.mutating(\.mediaSources, with: downloadedSource.map { [$0] }),
            mediaSource: downloadedSource
        ) { _, modifyItem in
            try await MediaPlayerItem.buildDownloaded(
                for: task,
                modifyItem: modifyItem
            )
        }
    }

    func downloadedEpisodes(under id: String) -> [DownloadTask] {
        descendants(of: id)
            .compactMap { task(id: $0) }
            .filter { !$0.isContainer && $0.isCompleted }
            .sorted { lhs, rhs in
                (lhs.item.parentIndexNumber ?? .max, lhs.item.indexNumber ?? .max) <
                    (rhs.item.parentIndexNumber ?? .max, rhs.item.indexNumber ?? .max)
            }
    }

    private func playableTask(for item: BaseItemDto) -> DownloadTask? {
        guard let id = item.id else { return nil }

        switch item.type {
        case .movie, .episode:
            guard let task = task(id: id), task.isCompleted else { return nil }
            return task
        case .series, .season, .boxSet:
            let episodes = downloadedEpisodes(under: id)
            return episodes.first { $0.item.userData?.isPlayed != true } ?? episodes.first
        default:
            return nil
        }
    }
}

extension MediaPlayerItem {

    static func buildDownloaded(
        for task: DownloadTask,
        modifyItem: (@Sendable (inout BaseItemDto) -> Void)? = nil
    ) async throws -> MediaPlayerItem {
        guard let mediaURL = task.mediaURL else {
            throw ErrorMessage("Missing downloaded media file")
        }

        var item = task.item

        if let modifyItem {
            modifyItem(&item)
        }

        guard let mediaSource = item.mediaSources?.first else {
            throw ErrorMessage("Missing media source for downloaded item")
        }

        let maxBitrate = try await MediaPlayerManager.getMaxBitrate(for: .max)

        let deviceProfile = DeviceProfile.build(
            for: Defaults[.VideoPlayer.videoPlayerType],
            compatibilityMode: Defaults[.VideoPlayer.Playback.compatibilityMode],
            maxBitrate: maxBitrate
        )

        return .init(
            baseItem: item,
            mediaSource: mediaSource,
            playSessionID: "",
            url: mediaURL,
            deviceProfile: deviceProfile,
            previewImageProvider: task.downloadedTrickplayPreviewImageProvider(),
            thumbnailProvider: item.getNowPlayingImage
        )
    }
}

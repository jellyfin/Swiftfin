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
            mediaSource: downloadedVersionMediaSource(for: task.id) ?? downloadedSource
        ) { _, modifyItem in
            try await MediaPlayerItem.buildDownloaded(
                for: task,
                modifyItem: modifyItem
            )
        }
    }

    func downloadedVersionMediaSource(for id: String) -> MediaSourceInfo? {
        guard let task = task(id: id),
              task.isCompleted,
              task.mediaURL != nil,
              var source = task.item.mediaSources?.first
        else { return nil }

        source.setDownloaded(true)

        return source
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
        case .series, .season, .boxSet, .person:
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

        guard var mediaSource = item.mediaSources?.first else {
            throw ErrorMessage("Missing media source for downloaded item")
        }

        mediaSource.mediaStreams = mediaSource.mediaStreams?.map { stream in
            guard stream.type == .subtitle,
                  stream.isExternal == true,
                  let localURL = task.localSubtitleURL(for: stream),
                  FileManager.default.fileExists(atPath: localURL.path)
            else { return stream }

            return stream.mutating(\.deliveryURL, with: localURL.absoluteString)
        }

        item.runTimeTicks = mediaSource.runTimeTicks ?? item.runTimeTicks

        if let runtime = item.runTimeTicks, runtime > 0,
           let position = item.userData?.playbackPositionTicks,
           Double(position) / Double(runtime) >= 0.9
        {
            item.userData?.playbackPositionTicks = 0
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

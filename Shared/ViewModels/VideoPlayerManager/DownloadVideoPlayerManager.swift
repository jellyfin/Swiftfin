//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

final class DownloadVideoPlayerManager: VideoPlayerManager {

    init(downloadTask: DownloadTask) {
        super.init()

        guard let playbackURL = downloadTask.getMediaURL() else {
            logger.error("Download task does not have media url for item: \(downloadTask.item.displayTitle)")
            return
        }

        // Get streams from the downloaded item
        let videoStreams = downloadTask.item.videoStreams
        let audioStreams = downloadTask.item.audioStreams
        let subtitleStreams = downloadTask.item.subtitleStreams

        // Use the first media source from the item if available, otherwise create empty one
        var mediaSource = downloadTask.item.mediaSources?.first ?? MediaSourceInfo()

        // Update the media source for local playback
        mediaSource.path = playbackURL.path
        mediaSource.isRemote = false
        mediaSource.isSupportsDirectPlay = true
        mediaSource.isSupportsDirectStream = true

        // Ensure media streams are populated
        if mediaSource.mediaStreams == nil || mediaSource.mediaStreams?.isEmpty == true {
            mediaSource.mediaStreams = videoStreams + audioStreams + subtitleStreams
        }

        self.currentViewModel = .init(
            playbackURL: playbackURL,
            item: downloadTask.item,
            mediaSource: mediaSource,
            playSessionID: "",
            videoStreams: videoStreams,
            audioStreams: audioStreams,
            subtitleStreams: subtitleStreams,
            selectedAudioStreamIndex: audioStreams.first?.index ?? 0,
            selectedSubtitleStreamIndex: subtitleStreams.first(where: { $0.isDefault ?? false })?.index ?? -1,
            chapters: downloadTask.item.fullChapterInfo,
            playMethod: .directPlay
        )
    }

    override func getAdjacentEpisodes(for item: BaseItemDto) {}

    override func sendStartReport() {}

    override func sendPauseReport() {}

    override func sendStopReport() {}

    override func sendProgressReport() {}
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

class DownloadVideoPlayerManager: VideoPlayerManager {

    init(downloadTask: DownloadTask) {
        super.init()

        guard let playbackURL = downloadTask.getMediaURL() else {
            logger.error("Download task does not have media url for item: \(downloadTask.item.displayTitle)")

            return
        }

        self.currentViewModel = .init(
            playbackURL: playbackURL,
            item: downloadTask.item,
            mediaSource: .init(),
            playSessionID: "",
            videoStreams: downloadTask.item.videoStreams,
            audioStreams: downloadTask.item.audioStreams,
            subtitleStreams: downloadTask.item.subtitleStreams,
            selectedAudioStreamIndex: 1,
            selectedSubtitleStreamIndex: 1,
            chapters: downloadTask.item.fullChapterInfo,
            streamType: .direct
        )
    }

    override func getAdjacentEpisodes(for item: BaseItemDto) {}

    override func sendStartReport() {}

    override func sendPauseReport() {}

    override func sendStopReport() {}

    override func sendProgressReport() {}
}

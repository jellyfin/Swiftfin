//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Factory
import Foundation
import JellyfinAPI
import SwiftUI
import VLCUI

class VideoPlayerViewModel: ObservableObject {

    class CurrentPlaybackInformation: ObservableObject {

        @Published
        var currentSeconds: Int = 0
        @Published
        var playbackInformation: VLCVideoPlayer.PlaybackInformation?

        func onTicksUpdated(ticks: Int, playbackInformation: VLCVideoPlayer.PlaybackInformation) {
            self.currentSeconds = ticks / 1000
            self.playbackInformation = playbackInformation
        }
    }

    @Published
    var subtitlesEnabled: Bool = false
    @Published
    var selectedSubtitleTrackIndex: Int32 = -1
    @Published
    var isAspectFilled: Bool = false

    var configuration: VLCVideoPlayer.Configuration {
        let configuration = VLCVideoPlayer.Configuration(url: playbackURL)
        configuration.autoPlay = true
        configuration.startTime = .seconds(item.startTimeSeconds)
        configuration.subtitleSize = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleSize])

        if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 0) {
            configuration.subtitleFont = .absolute(font)
        }

        configuration.playbackChildren = subtitleStreams
            .filter { $0.deliveryMethod == .external }
            .compactMap(\.asPlaybackChild)

        return configuration
    }

    let playbackURL: URL
    let item: BaseItemDto
    let videoStream: MediaStream
    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let chapters: [ChapterInfo.FullInfo]

    init(
        playbackURL: URL,
        item: BaseItemDto,
        videoStream: MediaStream,
        audioStreams: [MediaStream],
        subtitleStreams: [MediaStream],
        chapters: [ChapterInfo.FullInfo]
    ) {
        self.playbackURL = playbackURL
        self.item = item
        self.videoStream = videoStream
        self.audioStreams = audioStreams
        self.subtitleStreams = subtitleStreams
            .adjustExternalSubtitleIndexes(audioStreamCount: audioStreams.count)
        self.chapters = chapters
    }

    func chapter(from progress: CGFloat) -> ChapterInfo.FullInfo? {
        let seconds = Int(CGFloat(item.runTimeSeconds) * progress)
        return chapters.first(where: { $0.secondsRange.contains(seconds) })
    }
}

extension VideoPlayerViewModel: Equatable {

    static func == (lhs: VideoPlayerViewModel, rhs: VideoPlayerViewModel) -> Bool {
        lhs.playbackURL == rhs.playbackURL &&
            lhs.item == rhs.item
    }
}

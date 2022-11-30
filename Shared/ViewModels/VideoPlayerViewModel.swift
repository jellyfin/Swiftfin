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

class VLCVideoPlayerViewModel: ObservableObject {

    let playbackURL: URL
    let item: BaseItemDto
    let videoStream: MediaStream
    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let selectedAudioStreamIndex: Int
    let selectedSubtitleStreamIndex: Int
    let chapters: [ChapterInfo.FullInfo]
    let streamType: StreamType
    
    var configuration: VLCVideoPlayer.Configuration {
        let configuration = VLCVideoPlayer.Configuration(url: playbackURL)
        configuration.autoPlay = true
        configuration.startTime = .seconds(max(0, item.startTimeSeconds - Defaults[.VideoPlayer.resumeOffset]))
        configuration.audioIndex = .absolute(selectedAudioStreamIndex)
        configuration.subtitleIndex = .absolute(selectedSubtitleStreamIndex)
        configuration.subtitleSize = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleSize])

        if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 0) {
            configuration.subtitleFont = .absolute(font)
        }

        configuration.playbackChildren = subtitleStreams
            .filter { $0.deliveryMethod == .external }
            .compactMap(\.asPlaybackChild)

        return configuration
    }

    init(
        playbackURL: URL,
        item: BaseItemDto,
        videoStream: MediaStream,
        audioStreams: [MediaStream],
        subtitleStreams: [MediaStream],
        selectedAudioStreamIndex: Int,
        selectedSubtitleStreamIndex: Int,
        chapters: [ChapterInfo.FullInfo],
        streamType: StreamType
    ) {
        self.playbackURL = playbackURL
        self.item = item
        self.videoStream = videoStream
        self.audioStreams = audioStreams
        self.subtitleStreams = subtitleStreams
            .adjustExternalSubtitleIndexes(audioStreamCount: audioStreams.count)
        self.selectedAudioStreamIndex = selectedAudioStreamIndex
        self.selectedSubtitleStreamIndex = selectedSubtitleStreamIndex
        self.chapters = chapters
        self.streamType = streamType
    }

    func chapter(from seconds: Int) -> ChapterInfo.FullInfo? {
        chapters.first(where: { $0.secondsRange.contains(seconds) })
    }
}

extension VLCVideoPlayerViewModel: Equatable {

    static func == (lhs: VLCVideoPlayerViewModel, rhs: VLCVideoPlayerViewModel) -> Bool {
        lhs.playbackURL == rhs.playbackURL &&
            lhs.item == rhs.item
    }
}

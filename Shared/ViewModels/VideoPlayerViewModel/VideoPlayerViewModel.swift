//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Factory
import Foundation
import JellyfinAPI
import SwiftUI
import VLCUI

class CurrentSecondsHandler: ObservableObject {

    @Published
    var currentSeconds: Int = 0
    @Published
    var playbackInformation: VLCVideoPlayer.PlaybackInformation?

    func onTicksUpdated(ticks: Int, playbackInformation: VLCVideoPlayer.PlaybackInformation) {
        self.currentSeconds = ticks / 1000
        self.playbackInformation = playbackInformation
    }
}

class ItemVideoPlayerViewModel: ObservableObject, Equatable {

    static func == (lhs: ItemVideoPlayerViewModel, rhs: ItemVideoPlayerViewModel) -> Bool {
        lhs.playbackURL == rhs.playbackURL &&
            lhs.item == rhs.item
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
        self.chapters = chapters
    }

//    func videoSubtitleStreamIndex(of subtitleStreamIndex: Int) -> Int32 {
//        let externalSubtitleStreams = subtitleStreams.filter { $0.isExternal == true }
//
//        guard let externalSubtitleStreamIndex = externalSubtitleStreams.firstIndex(where: { $0.index == subtitleStreamIndex }) else {
//            return Int32(subtitleStreamIndex)
//        }
//
//        let embeddedSubtitleStreamCount = subtitleStreams.count - externalSubtitleStreams.count
//        let embeddedStreamCount = 1 + audioStreams.count + embeddedSubtitleStreamCount
//
//        return Int32(embeddedStreamCount + externalSubtitleStreamIndex)
//    }
}

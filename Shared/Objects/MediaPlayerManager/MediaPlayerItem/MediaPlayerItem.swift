//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import JellyfinAPI
import Logging
import MediaPlayer
import Nuke
import SwiftUI
import VLCUI

// TODO: decouple from VLCUI

class MediaPlayerItem: ViewModel, MediaPlayerObserver {

    typealias ThumnailProvider = () async -> UIImage?

    @Published
    var selectedAudioStreamIndex: Int? = nil {
        didSet {
            manager?.proxy?.setAudioStream(.init(index: selectedAudioStreamIndex))
        }
    }

    @Published
    var selectedSubtitleStreamIndex: Int? = nil {
        didSet {
            manager?.proxy?.setSubtitleStream(.init(index: selectedSubtitleStreamIndex))
        }
    }

    weak var manager: MediaPlayerManager? {
        didSet {
            for var o in observers {
                o.manager = manager
            }
        }
    }

    var observers: [any MediaPlayerObserver] = []
    var supplements: [any MediaPlayerSupplement] = []

    let baseItem: BaseItemDto
    let mediaSource: MediaSourceInfo
    let playSessionID: String
    let thumbnailProvider: ThumnailProvider?
    let url: URL

    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let videoStreams: [MediaStream]

    let vlcConfiguration: VLCVideoPlayer.Configuration

    // MARK: init

    init(
        baseItem: BaseItemDto,
        mediaSource: MediaSourceInfo,
        playSessionID: String,
        url: URL,
        thumbnailProvider: ThumnailProvider? = nil
    ) {
        self.baseItem = baseItem
        self.mediaSource = mediaSource
        self.playSessionID = playSessionID
        self.thumbnailProvider = thumbnailProvider
        self.url = url

        //        let adjustedMediaStreams = mediaSource.mediaStreams?.adjustedTrackIndexes(
        //            for: <#T##PlayMethod#>,
        //            selectedAudioStreamIndex: <#T##Int#>
        //        )
        //
        //        let adjustedMediaStreams = mediaSource.mediaStreams?.adjustedTrackIndexes(
        //            isTranscoded: mediaSource.transcodingURL != nil,
        //            selectedAudioStreamIndex: mediaSource.defaultAudioStreamIndex ?? 0
        //        )
        //
        //        let audioStreams = adjustedMediaStreams?.filter { $0.type == .audio } ?? []
        //        let subtitleStreams = adjustedMediaStreams?.filter { $0.type == .subtitle } ?? []
        //        let videoStreams = adjustedMediaStreams?.filter { $0.type == .video } ?? []

        //        self.audioStreams = audioStreams
        //        self.subtitleStreams = subtitleStreams
        //        self.videoStreams = videoStreams

        self.audioStreams = []
        self.subtitleStreams = []
        self.videoStreams = []

        var configuration = VLCVideoPlayer.Configuration(url: url)
        configuration.autoPlay = true

        let startSeconds = max(.zero, (baseItem.startSeconds ?? .zero) - Duration.seconds(Defaults[.VideoPlayer.resumeOffset]))

        if !baseItem.isLiveStream {
            configuration.startSeconds = startSeconds
            configuration.audioIndex = .absolute(mediaSource.defaultAudioStreamIndex ?? -1)
            configuration.subtitleIndex = .absolute(mediaSource.defaultSubtitleStreamIndex ?? -1)
        }

        configuration.subtitleSize = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleSize])
        configuration.subtitleColor = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleColor].uiColor)

        if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 0) {
            configuration.subtitleFont = .absolute(font)
        }

        //        configuration.playbackChildren = subtitleStreams
        //            .filter { $0.deliveryMethod == .external }
        //            .compactMap(\.asPlaybackChild)

        vlcConfiguration = configuration

        super.init()

        selectedAudioStreamIndex = mediaSource.defaultAudioStreamIndex ?? -1
        selectedSubtitleStreamIndex = mediaSource.defaultSubtitleStreamIndex ?? -1

        observers.append(MediaProgressObserver(item: self))

        supplements.append(MediaInfoSupplement(item: baseItem))

        let chapters = baseItem.fullChapterInfo

        if chapters.isNotEmpty {
            supplements.append(
                MediaChaptersSupplement(
                    chapters: baseItem.fullChapterInfo
                )
            )
        }
    }
}

extension BaseItemDto {

    func nowPlayableStaticMetadata(_ image: UIImage? = nil) -> NowPlayableStaticMetadata {

        let mediaType: MPNowPlayingInfoMediaType = {
            switch type {
            case .audio, .audioBook: .audio
            default: .video
            }
        }()

        // TODO: only fill artist, albumArtist, and albumTitle if audio type
        return .init(
            mediaType: mediaType,
            isLiveStream: isLiveStream,
            title: displayTitle,
            artist: nil,
            artwork: nil,
            albumArtist: nil,
            albumTitle: nil
        )
    }
}

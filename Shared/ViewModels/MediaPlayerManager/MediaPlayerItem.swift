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
import SwiftUI
import VLCUI

// TODO: rename `MediaPlaybackItem`?

class MediaPlayerItem: ViewModel, MediaPlayerListener {

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
            for var l in listeners {
                l.manager = manager
            }
        }
    }

    var listeners: [any MediaPlayerListener] = []
    var supplements: [any MediaPlayerSupplement] = []

    let baseItem: BaseItemDto
    let mediaSource: MediaSourceInfo
    let playSessionID: String
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
        url: URL
    ) {
        self.baseItem = baseItem
        self.mediaSource = mediaSource
        self.playSessionID = playSessionID
        self.url = url

        let audioStreams = mediaSource.audioStreams ?? []
        let subtitleStreams = mediaSource.subtitleStreams ?? []

        let startSeconds = max(0, baseItem.startTimeSeconds - TimeInterval(Defaults[.VideoPlayer.resumeOffset]))

        self.videoStreams = mediaSource.videoStreams ?? []
        self.audioStreams = audioStreams
            .adjustAudioForExternalSubtitles(externalMediaStreamCount: subtitleStreams.filter { $0.isExternal ?? false }.count)
        self.subtitleStreams = subtitleStreams
            .adjustExternalSubtitleIndexes(audioStreamCount: audioStreams.count)

        let configuration = VLCVideoPlayer.Configuration(url: url)
        configuration.autoPlay = true

        if !baseItem.isLiveStream {
            configuration.startTime = .seconds(startSeconds)
            configuration.audioIndex = .absolute(mediaSource.defaultAudioStreamIndex ?? -1)
            configuration.subtitleIndex = .absolute(mediaSource.defaultSubtitleStreamIndex ?? -1)
        }

        configuration.subtitleSize = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleSize])
        configuration.subtitleColor = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleColor].uiColor)

        if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 0) {
            configuration.subtitleFont = .absolute(font)
        }

        configuration.playbackChildren = subtitleStreams
            .filter { $0.deliveryMethod == .external }
            .compactMap(\.asPlaybackChild)

        vlcConfiguration = configuration

        super.init()

        selectedAudioStreamIndex = mediaSource.defaultAudioStreamIndex ?? -1
        selectedSubtitleStreamIndex = mediaSource.defaultSubtitleStreamIndex ?? -1

        listeners.append(MediaProgressListener(item: self))
    }

    // MARK: build

    static func build(for item: BaseItemDto, mediaSource: MediaSourceInfo) async throws -> MediaPlayerItem {

        let logger = Container.shared.logService()

        let currentVideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
        let currentVideoBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate]
        let compatibilityMode = Defaults[.VideoPlayer.Playback.compatibilityMode]

        let maxBitrate = try await currentVideoBitrate.getMaxBitrate()

        let profile = DeviceProfile.build(
            for: currentVideoPlayerType,
            compatibilityMode: compatibilityMode,
            maxBitrate: maxBitrate
        )

        guard let userSession = Container.shared.currentUserSession() else {
            logger.error("No user session while building online media player item!")
            throw JellyfinAPIError(L10n.unknownError)
        }

        let playbackInfo = PlaybackInfoDto(deviceProfile: profile)
        let playbackInfoParameters = Paths.GetPostedPlaybackInfoParameters(
            userID: userSession.user.id,
            maxStreamingBitrate: maxBitrate
        )

        let request = Paths.getPostedPlaybackInfo(
            itemID: item.id!,
            parameters: playbackInfoParameters,
            playbackInfo
        )

        let response = try await userSession.client.send(request)

        let matchingMediaSource: MediaSourceInfo? = {

            guard let mediaSources = response.value.mediaSources else { return nil }

            if let matchingTag = mediaSources.first(where: { $0.eTag == mediaSource.eTag }) {
                return matchingTag
            }

            for source in mediaSources {
                if let openToken = source.openToken,
                   let id = source.id,
                   openToken.contains(id)
                {
                    return source
                }
            }

            logger.warning("Unable to find matching media source, defaulting to first media source")

            return mediaSources.first
        }()

        guard let matchingMediaSource else {
            throw JellyfinAPIError("Unable to find media source for item")
        }

        guard let playSessionID = response.value.playSessionID else {
            throw JellyfinAPIError("No associated play session ID")
        }

        let playbackURL: URL

        if let transcodingURL = matchingMediaSource.transcodingURL {
            guard let fullTranscodeURL = userSession.client.fullURL(with: transcodingURL)
            else { throw JellyfinAPIError("Unable to make transcode URL") }
            playbackURL = fullTranscodeURL
        } else {
            let videoStreamParameters = Paths.GetVideoStreamParameters(
                isStatic: true,
                tag: item.etag,
                playSessionID: playSessionID,
                mediaSourceID: item.id
            )

            let videoStreamRequest = Paths.getVideoStream(
                itemID: item.id!,
                parameters: videoStreamParameters
            )

            guard let streamURL = userSession.client.fullURL(with: videoStreamRequest)
            else { throw JellyfinAPIError("Unable to make stream URL") }

            playbackURL = streamURL
        }

        return .init(
            baseItem: item,
            mediaSource: matchingMediaSource,
            playSessionID: playSessionID,
            url: playbackURL
        )
    }
}

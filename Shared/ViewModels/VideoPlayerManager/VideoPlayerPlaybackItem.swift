//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import SwiftUI
import VLCUI

// struct ProgressBox {
//
//    var progress: CGFloat
//    var seconds: Int
// }

class ProgressBox: ObservableObject {

    @Published
    var progress: CGFloat
    @Published
    var seconds: Int

    init(progress: CGFloat = 0, seconds: Int = 0) {
        self.progress = progress
        self.seconds = seconds
    }
}

// TODO: register metadata with now playing

class VideoPlayerPlaybackItem: ViewModel {

    let baseItem: BaseItemDto
    let chapters: [ChapterInfo.FullInfo]
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
        self.chapters = baseItem.fullChapterInfo
        self.mediaSource = mediaSource
        self.playSessionID = playSessionID
        self.url = url

        let audioStreams = mediaSource.audioStreams ?? []
        let subtitleStreams = mediaSource.subtitleStreams ?? []

        let startSeconds = max(0, baseItem.startTimeSeconds - Defaults[.VideoPlayer.resumeOffset])

        self.videoStreams = mediaSource.videoStreams ?? []
        self.audioStreams = audioStreams
            .adjustAudioForExternalSubtitles(externalMediaStreamCount: subtitleStreams.filter { $0.isExternal ?? false }.count)
        self.subtitleStreams = subtitleStreams
            .adjustExternalSubtitleIndexes(audioStreamCount: audioStreams.count)

        let configuration = VLCVideoPlayer.Configuration(url: url)
        configuration.autoPlay = true
        configuration.startTime = .seconds(startSeconds)
        configuration.audioIndex = .absolute(mediaSource.defaultAudioStreamIndex ?? -1)
        configuration.subtitleIndex = .absolute(mediaSource.defaultSubtitleStreamIndex ?? -1)
        configuration.subtitleSize = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleSize])
        configuration.subtitleColor = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleColor].uiColor)

        if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 0) {
            configuration.subtitleFont = .absolute(font)
        }

        configuration.playbackChildren = subtitleStreams
            .filter { $0.deliveryMethod == .external }
            .compactMap(\.asPlaybackChild)

        vlcConfiguration = configuration
    }

    // MARK: stateDidChange

    func stateDidChange(newState: VideoPlayerManager.State) {}

    // MARK: playbackTimeDidChange

    func playbackTimeDidChange(newSeconds: Int) {}

    // MARK: build

    static func build(for item: BaseItemDto, mediaSource: MediaSourceInfo) async throws -> VideoPlayerPlaybackItem {

        let currentVideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
        let currentVideoBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate]
        let compatibilityMode = Defaults[.VideoPlayer.Playback.compatibilityMode]

        let maxBitrate = try await currentVideoBitrate.getMaxBitrate()

        let profile = DeviceProfile.build(
            for: currentVideoPlayerType,
            compatibilityMode: compatibilityMode,
            maxBitrate: maxBitrate
        )

        let userSession = Container.shared.currentUserSession()!

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

        guard let matchingMediaSource = response.value.mediaSources?
            .first(where: { $0.eTag == mediaSource.eTag && $0.id == mediaSource.id })
        else {
            throw JellyfinAPIError("Matching media source not in playback info")
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

        return VideoPlayerPlaybackItem(
            baseItem: item,
            mediaSource: matchingMediaSource,
            playSessionID: playSessionID,
            url: playbackURL
        )
    }
}

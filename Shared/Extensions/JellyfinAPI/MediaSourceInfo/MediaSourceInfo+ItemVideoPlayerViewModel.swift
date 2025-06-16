//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import Logging
import UIKit

// TODO: strongly type errors

extension MediaSourceInfo {

    /// Simple Atmos track prioritization - only applies to Native player
    func selectBestAudioStreamIndex() -> Int {
        let logger = Logger(label: "MediaSourceInfo.selectBestAudioStreamIndex")
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        logger.debug("Found \(audioStreams.count) audio streams")

        for (i, stream) in audioStreams.enumerated() {
            logger
                .debug(
                    "Stream \(i): index=\(stream.index ?? -1), codec=\(stream.codec ?? "unknown"), profile=\(stream.profile ?? "none"), isEAC3Atmos=\(stream.isEAC3Atmos)"
                )
        }

        guard !audioStreams.isEmpty else {
            logger.debug("No audio streams found, returning -1")
            return -1
        }

        let currentVideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
        let preferAtmos = Defaults[Defaults.Keys.VideoPlayer.preferDolbyAtmos]
        logger.debug("Current player type: \(currentVideoPlayerType), Prefer Atmos setting: \(preferAtmos)")

        // Only apply Atmos preference for Native player (AVKit), not VLC/Swiftfin player
        if currentVideoPlayerType == .native && preferAtmos,
           let atmosStream = audioStreams.first(where: { $0.isEAC3Atmos }),
           let index = atmosStream.index
        {
            logger.info("Native player with Atmos preference - using Atmos stream at index \(index)")
            return index
        }

        let fallbackIndex = defaultAudioStreamIndex ?? audioStreams.first?.index ?? -1
        logger.debug("Using default audio stream selection logic, fallback index: \(fallbackIndex)")
        return fallbackIndex
    }

    func videoPlayerViewModel(with item: BaseItemDto, playSessionID: String, selectedAudioStreamIndex: Int) throws -> VideoPlayerViewModel {

        let userSession: UserSession! = Container.shared.currentUserSession()
        let playbackURL: URL
        let playMethod: PlayMethod

        if let transcodingURL {
            guard let fullTranscodeURL = userSession.client.fullURL(with: transcodingURL)
            else { throw JellyfinAPIError("Unable to make transcode URL") }
            playbackURL = fullTranscodeURL
            playMethod = .transcode
        } else {
            let videoStreamParameters = Paths.GetVideoStreamParameters(
                isStatic: true,
                tag: item.etag,
                playSessionID: playSessionID,
                mediaSourceID: id
            )

            let videoStreamRequest = Paths.getVideoStream(
                itemID: item.id!,
                parameters: videoStreamParameters
            )

            guard let streamURL = userSession.client.fullURL(with: videoStreamRequest)
            else { throw JellyfinAPIError("Unable to make stream URL") }

            playbackURL = streamURL
            playMethod = .directPlay
        }

        let videoStreams = mediaStreams?.filter { $0.type == .video } ?? []
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        let subtitleStreams = mediaStreams?.filter { $0.type == .subtitle } ?? []

        return .init(
            playbackURL: playbackURL,
            item: item,
            mediaSource: self,
            playSessionID: playSessionID,
            videoStreams: videoStreams,
            audioStreams: audioStreams,
            subtitleStreams: subtitleStreams,
            selectedAudioStreamIndex: selectedAudioStreamIndex,
            selectedSubtitleStreamIndex: defaultSubtitleStreamIndex ?? -1,
            chapters: item.fullChapterInfo,
            playMethod: playMethod
        )
    }

    func liveVideoPlayerViewModel(with item: BaseItemDto, playSessionID: String) throws -> VideoPlayerViewModel {

        let userSession: UserSession! = Container.shared.currentUserSession()
        let playbackURL: URL
        let playMethod: PlayMethod

        if let transcodingURL {
            guard let fullTranscodeURL = URL(string: transcodingURL, relativeTo: userSession.server.currentURL)
            else { throw JellyfinAPIError("Unable to construct transcoded url") }
            playbackURL = fullTranscodeURL
            playMethod = .transcode
        } else if self.isSupportsDirectPlay ?? false, let path = self.path, let playbackUrl = URL(string: path) {
            playbackURL = playbackUrl
            playMethod = .directPlay
        } else {
            let videoStreamParameters = Paths.GetVideoStreamParameters(
                isStatic: true,
                tag: item.etag,
                playSessionID: playSessionID,
                mediaSourceID: id
            )

            let videoStreamRequest = Paths.getVideoStream(
                itemID: item.id!,
                parameters: videoStreamParameters
            )

            guard let fullURL = userSession.client.fullURL(with: videoStreamRequest) else {
                throw JellyfinAPIError("Unable to construct transcoded url")
            }
            playbackURL = fullURL
            playMethod = .directPlay
        }

        let videoStreams = mediaStreams?.filter { $0.type == .video } ?? []
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        let subtitleStreams = mediaStreams?.filter { $0.type == .subtitle } ?? []

        return .init(
            playbackURL: playbackURL,
            item: item,
            mediaSource: self,
            playSessionID: playSessionID,
            videoStreams: videoStreams,
            audioStreams: audioStreams,
            subtitleStreams: subtitleStreams,
            selectedAudioStreamIndex: defaultAudioStreamIndex ?? -1,
            selectedSubtitleStreamIndex: defaultSubtitleStreamIndex ?? -1,
            chapters: item.fullChapterInfo,
            playMethod: playMethod
        )
    }
}

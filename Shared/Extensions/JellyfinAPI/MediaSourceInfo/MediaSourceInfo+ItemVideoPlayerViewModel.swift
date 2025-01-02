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
import UIKit

// TODO: strongly type errors

extension MediaSourceInfo {

    func videoPlayerViewModel(with item: BaseItemDto, playSessionID: String) throws -> VideoPlayerViewModel {

        let userSession: UserSession! = Container.shared.currentUserSession()
        let playbackURL: URL
        let streamType: StreamType

        if let transcodingURL {
            guard let fullTranscodeURL = userSession.client.fullURL(with: transcodingURL)
            else { throw JellyfinAPIError("Unable to make transcode URL") }
            playbackURL = fullTranscodeURL
            streamType = .transcode
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
            streamType = .direct
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
            streamType: streamType
        )
    }

    func liveVideoPlayerViewModel(with item: BaseItemDto, playSessionID: String) throws -> VideoPlayerViewModel {

        let userSession: UserSession! = Container.shared.currentUserSession()
        let playbackURL: URL
        let streamType: StreamType

        if let transcodingURL {
            guard let fullTranscodeURL = URL(string: transcodingURL, relativeTo: userSession.server.currentURL)
            else { throw JellyfinAPIError("Unable to construct transcoded url") }
            playbackURL = fullTranscodeURL
            streamType = .transcode
        } else if self.isSupportsDirectPlay ?? false, let path = self.path, let playbackUrl = URL(string: path) {
            playbackURL = playbackUrl
            streamType = .direct
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
            streamType = .direct
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
            streamType: streamType
        )
    }
}

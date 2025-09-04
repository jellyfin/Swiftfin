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
import Nuke
import UIKit

extension MediaPlayerItem {

    /// The main `MediaPlayerItem` builder for normal online usage.
    static func build(
        for item: BaseItemDto,
        mediaSource: MediaSourceInfo,
        videoPlayerType: VideoPlayerType = Defaults[.VideoPlayer.videoPlayerType],
        requestedBitrate: PlaybackBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate],
        compatibilityMode: PlaybackCompatibility = Defaults[.VideoPlayer.Playback.compatibilityMode]
    ) async throws -> MediaPlayerItem {

        let logger = Logger.swiftfin()

        let maxBitrate = try await requestedBitrate.getMaxBitrate()

        let profile = DeviceProfile.build(
            for: videoPlayerType,
            compatibilityMode: compatibilityMode,
            maxBitrate: maxBitrate
        )

        guard let userSession = Container.shared.currentUserSession() else {
            logger.critical("No user session while building online media player item!")
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

        func getNowPlayingImage() async -> UIImage? {
            let imageRequests = item.portraitImageSources(maxWidth: 100, quality: 90)
            return await ImagePipeline.Swiftfin.other.loadFirstImage(from: imageRequests)
        }

        return .init(
            baseItem: item,
            mediaSource: matchingMediaSource,
            playSessionID: playSessionID,
            url: playbackURL,
            requestedBitrate: requestedBitrate,
            thumbnailProvider: getNowPlayingImage
        )
    }
}

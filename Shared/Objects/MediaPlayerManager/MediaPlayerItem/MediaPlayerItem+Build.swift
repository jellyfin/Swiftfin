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
        for initialItem: BaseItemDto,
        mediaSource initialMediaSource: MediaSourceInfo,
        videoPlayerType: VideoPlayerType = Defaults[.VideoPlayer.videoPlayerType],
        requestedBitrate: PlaybackBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate],
        compatibilityMode: PlaybackCompatibility = Defaults[.VideoPlayer.Playback.compatibilityMode]
    ) async throws -> MediaPlayerItem {

        let logger = Logger.swiftfin()

        guard let itemID = initialItem.id else {
            logger.critical("No item ID while building online media player item!")
            throw JellyfinAPIError(L10n.unknownError)
        }

        guard let userSession = Container.shared.currentUserSession() else {
            logger.critical("No user session while building online media player item!")
            throw JellyfinAPIError(L10n.unknownError)
        }

        let item = try await initialItem.getFullItem(userSession: userSession)

        let maxBitrate = try await requestedBitrate.getMaxBitrate()

        let deviceProfile = DeviceProfile.build(
            for: videoPlayerType,
            compatibilityMode: compatibilityMode,
            maxBitrate: maxBitrate
        )

        var playbackInfo = PlaybackInfoDto()
        playbackInfo.isAutoOpenLiveStream = true
        playbackInfo.deviceProfile = deviceProfile
        playbackInfo.liveStreamID = initialMediaSource.liveStreamID
        playbackInfo.maxStreamingBitrate = maxBitrate
        playbackInfo.userID = userSession.user.id

        let request = Paths.getPostedPlaybackInfo(
            itemID: itemID,
            playbackInfo
        )

        let response = try await userSession.client.send(request)

        let mediaSource: MediaSourceInfo? = {

            guard let mediaSources = response.value.mediaSources else { return nil }

            if let matchingTag = mediaSources.first(where: { $0.eTag == initialMediaSource.eTag }) {
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

        guard let mediaSource else {
            throw JellyfinAPIError("Unable to find media source for item")
        }

        guard let playSessionID = response.value.playSessionID else {
            throw JellyfinAPIError("No associated play session ID")
        }

        let playbackURL = try Self.streamURL(
            item: item,
            mediaSource: mediaSource,
            playSessionID: playSessionID,
            userSession: userSession
        )

        func getNowPlayingImage() async -> UIImage? {
            let imageRequests = item.portraitImageSources(maxWidth: 100, quality: 90)
            return await ImagePipeline.Swiftfin.other.loadFirstImage(from: imageRequests)
        }

        let previewImageProvider: (any PreviewImageProvider)? = {
            let previewImageScrubbingSetting = StoredValues[.User.previewImageScrubbing]
            lazy var chapterPreviewImageProvider: ChapterPreviewImageProvider? = {
                if let chapters = item.fullChapterInfo, chapters.isNotEmpty {
                    return ChapterPreviewImageProvider(chapters: chapters)
                }
                return nil
            }()

            if case let PreviewImageScrubbingOption.trickplay(fallbackToChapters: fallbackToChapters) = previewImageScrubbingSetting {
                if let mediaSourceID = initialMediaSource.id,
                   let trickplayInfo = item.trickplay?[mediaSourceID]?.first
                {
                    return TrickplayPreviewImageProvider(
                        info: trickplayInfo.value,
                        itemID: itemID,
                        mediaSourceID: mediaSourceID,
                        runtime: item.runtime ?? .zero
                    )
                }

                if fallbackToChapters {
                    return chapterPreviewImageProvider
                }
            } else if previewImageScrubbingSetting == .chapters {
                return chapterPreviewImageProvider
            }

            return nil
        }()

        return .init(
            baseItem: item,
            mediaSource: mediaSource,
            playSessionID: playSessionID,
            url: playbackURL,
            requestedBitrate: requestedBitrate,
            previewImageProvider: previewImageProvider,
            thumbnailProvider: getNowPlayingImage
        )
    }

    // TODO: audio type stream
    // TODO: build live tv stream from Paths.getLiveHlsStream?
    private static func streamURL(
        item: BaseItemDto,
        mediaSource: MediaSourceInfo,
        playSessionID: String,
        userSession: UserSession
    ) throws -> URL {

        guard let itemID = item.id else {
            throw JellyfinAPIError("No item ID while building online media player item!")
        }

        if let transcodingURL = mediaSource.transcodingURL {
            guard let fullTranscodeURL = userSession.client.fullURL(with: transcodingURL)
            else { throw JellyfinAPIError("Unable to make transcode URL") }
            return fullTranscodeURL
        }

        if item.mediaType == .video, !item.isLiveStream {

            let videoStreamParameters = Paths.GetVideoStreamParameters(
                isStatic: true,
                tag: item.etag,
                playSessionID: playSessionID,
                mediaSourceID: itemID
            )

            let videoStreamRequest = Paths.getVideoStream(
                itemID: itemID,
                parameters: videoStreamParameters
            )

            guard let videoStreamURL = userSession.client.fullURL(with: videoStreamRequest)
            else { throw JellyfinAPIError("Unable to make video stream URL") }

            return videoStreamURL
        }

        guard let path = mediaSource.path, let streamURL = URL(
            string: path
        ) else { throw JellyfinAPIError("Unable to make stream URL") }

        return streamURL
    }
}

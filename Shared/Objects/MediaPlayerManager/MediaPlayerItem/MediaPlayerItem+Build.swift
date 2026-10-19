//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import Logging

extension MediaPlayerItem {

    static func build(
        for initialItem: BaseItemDto,
        userSession: UserSession,
        mediaSource _initialMediaSource: MediaSourceInfo? = nil,
        audioStreamIndex: Int? = nil,
        subtitleStreamIndex: Int? = nil,
        secondarySubtitleStreamIndex: Int? = nil,
        mediaPlayerType: MediaPlayerType,
        requestedBitrate: PlaybackBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate],
        compatibilityMode: PlaybackCompatibility = Defaults[.VideoPlayer.Playback.compatibilityMode],
        modifyItem: ((inout BaseItemDto) -> Void)? = nil
    ) async throws -> MediaPlayerItem {

        let logger = Logger.swiftfin()

        guard let itemID = initialItem.id else {
            logger.critical("No item ID!")
            throw ErrorMessage(L10n.unknownError)
        }

        // Keep the shared record alive through playback setup
        let storedItem = try await userSession.getFullItem(initialItem)
        guard var item = storedItem.value else { throw ItemStore.StoreError.itemUnavailable }

        // Playback overrides apply to this copy without updating the shared record
        modifyItem?(&item)

        guard let initialMediaSource = {
            if let _initialMediaSource {
                return _initialMediaSource
            }

            if let first = item.mediaSources?.first {
                logger.trace("Using first media source for item \(itemID)")
                return first
            }

            return nil
        }() else {
            logger.error("No media sources for item \(itemID)!")
            throw ErrorMessage(L10n.unknownError)
        }

        let maxBitrate = try await getMaxBitrate(for: requestedBitrate, userSession: userSession)

        let deviceProfile = DeviceProfile.build(
            for: mediaPlayerType,
            compatibilityMode: compatibilityMode,
            maxBitrate: maxBitrate,
            mediaSource: initialMediaSource
        )

        // Resolve accessibility choices before negotiating a transcode or burned-in subtitles.
        let selection = MediaPlaybackPreferences.current.selection(
            in: initialMediaSource, audio: audioStreamIndex, subtitle: subtitleStreamIndex
        )

        var playbackInfo = PlaybackInfoDto()
        playbackInfo.isAutoOpenLiveStream = true
        playbackInfo.deviceProfile = deviceProfile
        playbackInfo.liveStreamID = initialMediaSource.liveStreamID
        playbackInfo.maxStreamingBitrate = maxBitrate
        playbackInfo.userID = userSession.user.id
        playbackInfo.audioStreamIndex = selection.audio
        playbackInfo.subtitleStreamIndex = selection.subtitle

        if !item.isLiveStream, initialMediaSource.type != .placeholder {
            playbackInfo.mediaSourceID = initialMediaSource.id
        }

        let request = Paths.getPostedPlaybackInfo(
            itemID: itemID,
            playbackInfo
        )

        try userSession.items.validate()
        let client = userSession.client

        // An opening request must return its live-stream IDs even if the intent is superseded.
        let response = try await Task { try await client.send(request) }.value

        do {
            try userSession.items.validate()

            guard storedItem.value != nil else { throw ItemStore.StoreError.itemUnavailable }

            let mediaSource: MediaSourceInfo? = {

                guard let mediaSources = response.value.mediaSources else { return nil }

                if let tag = initialMediaSource.eTag,
                   let matchingTag = mediaSources.first(where: { $0.eTag == tag })
                {
                    return matchingTag
                }

                if let initialID = initialMediaSource.id,
                   let matchingMediaSource = mediaSources.first(where: { $0.id == initialID })
                {
                    return matchingMediaSource
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
                throw ErrorMessage("Unable to find media source for item")
            }

            item.runTimeTicks = mediaSource.runTimeTicks ?? item.runTimeTicks

            guard let playSessionID = response.value.playSessionID else {
                throw ErrorMessage("No associated play session ID")
            }

            let playbackURL = try Self.streamURL(
                item: item,
                mediaSource: mediaSource,
                playSessionID: playSessionID,
                userSession: userSession,
                logger: logger
            )

            let automaticTrackDefaults = MediaPlaybackPreferences.Selection(
                audio: initialMediaSource.defaultAudioStreamIndex
                    ?? (selection.audio == nil ? mediaSource.defaultAudioStreamIndex : nil)
                    ?? initialMediaSource.mediaStreams?.first(where: { $0.type == .audio && $0.isDefault == true })?.index
                    ?? initialMediaSource.mediaStreams?.first(where: { $0.type == .audio && $0.isExternal != true })?.index,
                subtitle: initialMediaSource.defaultSubtitleStreamIndex
                    ?? (selection.subtitle == nil ? mediaSource.defaultSubtitleStreamIndex : -1)
            )

            let chapters = item.fullChapterInfo(using: client)
            let temporaryFiles = PlaybackTemporaryFiles(accessToken: client.accessToken)

            let previewImageProvider = PreviewImageProvider(
                option: StoredValues[.User.previewImageScrubbing],
                item: item,
                mediaSourceID: mediaSource.id,
                chapters: chapters,
                client: client,
                resolveImage: temporaryFiles.image(for:)
            )

            return .init(
                baseItem: item,
                mediaSource: mediaSource,
                playSessionID: playSessionID,
                url: playbackURL,
                requestedBitrate: requestedBitrate,
                deviceProfile: deviceProfile,
                initialAudioStreamIndex: selection.audio,
                initialSubtitleStreamIndex: selection.subtitle,
                initialSecondarySubtitleStreamIndex: secondarySubtitleStreamIndex,
                automaticTrackDefaults: automaticTrackDefaults,
                chapters: chapters,
                temporaryFiles: temporaryFiles,
                previewImageProvider: previewImageProvider,
                thumbnailProvider: { await storedItem.value?.getNowPlayingImage() }
            )
        } catch {
            closeLiveStreams(response.value.mediaSources ?? [], userSession: userSession)
            throw error
        }
    }

    private static func getMaxBitrate(
        for requestedBitrate: PlaybackBitrate,
        userSession: UserSession,
        testSize: PlaybackBitrateTestSize = Defaults[.VideoPlayer.Playback.appMaximumBitrateTest]
    ) async throws -> Int {
        guard requestedBitrate == .auto else { return requestedBitrate.rawValue }

        let start = ContinuousClock.now
        _ = try await userSession.send(Paths.getBitrateTestBytes(size: testSize.rawValue))

        let seconds = max(start.duration(to: .now).seconds, 0.001)
        let measuredBitrate = Double(testSize.rawValue * 8) / seconds

        return Int(clamp(
            measuredBitrate,
            min: Double(PlaybackBitrate.kbps420.rawValue),
            max: Double(Int32.max)
        ))
    }

    /// An abandoned resolution can have opened a live stream before a player ever loads its URL.
    static func closeLiveStreams(_ mediaSources: [MediaSourceInfo], userSession: UserSession) {
        let streamIDs = Set(mediaSources.compactMap(\.liveStreamID))
        guard !streamIDs.isEmpty else { return }

        let client = userSession.client

        Task {
            for streamID in streamIDs {
                _ = try? await client.send(Paths.closeLiveStream(liveStreamID: streamID))
            }
        }
    }

    private static func streamURL(
        item: BaseItemDto,
        mediaSource: MediaSourceInfo,
        playSessionID: String,
        userSession: UserSession,
        logger: Logger
    ) throws -> URL {

        guard let itemID = item.id else {
            throw ErrorMessage("No item ID while building online media player item!")
        }

        if let transcodingPath = mediaSource.transcodingURL {
            logger.trace("Using transcoding URL for item \(itemID)")

            guard let url = userSession.client.url(path: transcodingPath) else {
                throw ErrorMessage("Unable to make transcoding URL")
            }

            return url
        }

        if item.mediaType == .video {

            logger.trace("Making video stream URL for item \(itemID)")

            let videoStreamParameters = Paths.GetVideoStreamParameters(
                isStatic: true,
                tag: mediaSource.eTag ?? item.etag,
                playSessionID: playSessionID,
                mediaSourceID: mediaSource.id ?? itemID,
                liveStreamID: mediaSource.liveStreamID
            )

            let videoStreamRequest = Paths.getVideoStream(
                itemID: itemID,
                parameters: videoStreamParameters
            )

            guard let videoStreamURL = userSession.client.url(with: videoStreamRequest, queryAPIKey: true)
            else { throw ErrorMessage("Unable to make video stream URL") }

            return videoStreamURL
        }

        if item.mediaType == .audio {
            logger.trace("Making audio stream URL for item \(itemID)")

            let parameters = Paths.GetAudioStreamParameters(
                isStatic: true,
                tag: mediaSource.eTag ?? item.etag,
                playSessionID: playSessionID,
                mediaSourceID: mediaSource.id ?? itemID,
                liveStreamID: mediaSource.liveStreamID
            )

            let request = Paths.getAudioStream(itemID: itemID, parameters: parameters)
            guard let url = userSession.client.url(with: request, queryAPIKey: true) else {
                throw ErrorMessage("Unable to make audio stream URL")
            }

            return url
        }

        throw ErrorMessage("Unsupported playback media type")
    }
}

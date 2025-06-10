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

extension BaseItemDto {

    func videoPlayerViewModel(with mediaSource: MediaSourceInfo, audioStreamIndex: Int? = nil) async throws -> VideoPlayerViewModel {

        let logger = Container.shared.logService()
        let currentVideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
        let currentVideoBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate]
        let compatibilityMode = Defaults[.VideoPlayer.Playback.compatibilityMode]

        logger.debug("Current video bitrate setting: \(currentVideoBitrate) (raw value: \(currentVideoBitrate.rawValue))")
        let maxBitrate = try await getMaxBitrate(for: currentVideoBitrate)
        logger.debug("Calculated max bitrate: \(maxBitrate)")
        let profile = DeviceProfile.build(
            for: currentVideoPlayerType,
            with: self,
            compatibilityMode: compatibilityMode,
            maxBitrate: maxBitrate
        )

        let userSession = Container.shared.currentUserSession()!

        let playbackInfo = PlaybackInfoDto(
            audioStreamIndex: audioStreamIndex,
            deviceProfile: profile
        )
        let playbackInfoParameters = Paths.GetPostedPlaybackInfoParameters(
            userID: userSession.user.id,
            maxStreamingBitrate: maxBitrate,
            audioStreamIndex: audioStreamIndex,
            mediaSourceID: mediaSource.id
        )

        let request = Paths.getPostedPlaybackInfo(
            itemID: self.id!,
            parameters: playbackInfoParameters,
            playbackInfo
        )

        logger.debug("Media source container: \(mediaSource.container ?? "unknown")")
        logger.debug("Media source bitrate: \(mediaSource.bitrate ?? -1)")
        logger.debug("Media source size: \(mediaSource.size ?? -1)")
        if let videoStream = mediaSource.mediaStreams?.first(where: { $0.type == .video }) {
            logger.debug("Video stream bitrate: \(videoStream.bitRate ?? -1)")
            logger.debug("Video stream codec: \(videoStream.codec ?? "unknown")")
        }
        logger.debug("Requesting playback info with audioStreamIndex: \(audioStreamIndex ?? -1)")
        // Note: Not logging URL as it contains API key
        if let httpBody = request.body {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            if let data = try? encoder.encode(httpBody), let jsonString = String(data: data, encoding: .utf8) {
                logger.debug("Request body: \(jsonString)")
            }
        }
        let response = try await userSession.client.send(request)

        guard let matchingMediaSource = response.value.mediaSources?
            .first(where: { $0.eTag == mediaSource.eTag && $0.id == mediaSource.id })
        else {
            throw JellyfinAPIError("Matching media source not in playback info")
        }

        return try matchingMediaSource.videoPlayerViewModel(
            with: self,
            playSessionID: response.value.playSessionID!,
            audioStreamIndex: audioStreamIndex
        )
    }

    func liveVideoPlayerViewModel(with mediaSource: MediaSourceInfo, logger: Logger) async throws -> VideoPlayerViewModel {

        let currentVideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
        let currentVideoBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrate]
        let compatibilityMode = Defaults[.VideoPlayer.Playback.compatibilityMode]

        let maxBitrate = try await getMaxBitrate(for: currentVideoBitrate)
        let profile = DeviceProfile.build(
            for: currentVideoPlayerType,
            with: self,
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
            itemID: self.id!,
            parameters: playbackInfoParameters,
            playbackInfo
        )

        let response = try await userSession.client.send(request)
        logger.debug("liveVideoPlayerViewModel response received")

        var matchingMediaSource: MediaSourceInfo?
        if let responseMediaSources = response.value.mediaSources {
            for responseMediaSource in responseMediaSources {
                if let openToken = responseMediaSource.openToken, let mediaSourceId = mediaSource.id {
                    if openToken.contains(mediaSourceId) {
                        logger.debug("liveVideoPlayerViewModel found mediaSource with through openToken mediaSourceId match")
                        matchingMediaSource = responseMediaSource
                    }
                }
            }
            if matchingMediaSource == nil && !responseMediaSources.isEmpty {
                // Didn't find a match, but maybe we can just grab the first item in the response
                matchingMediaSource = responseMediaSources.first
                logger.debug("liveVideoPlayerViewModel resorting to first media source in the response")
            }
        }
        guard let matchingMediaSource else {
            logger.debug("liveVideoPlayerViewModel no matchingMediaSource found, throwing error")
            throw JellyfinAPIError("Matching media source not in playback info")
        }

        logger.debug("liveVideoPlayerViewModel matchingMediaSource being returned")
        return try matchingMediaSource.liveVideoPlayerViewModel(
            with: self,
            playSessionID: response.value.playSessionID!
        )
    }

    private func getMaxBitrate(for bitrate: PlaybackBitrate) async throws -> Int {
        let logger = Container.shared.logService()
        let settingBitrate = Defaults[.VideoPlayer.Playback.appMaximumBitrateTest]
        logger.debug("getMaxBitrate called with bitrate: \(bitrate)")
        logger.debug("settingBitrate for test: \(settingBitrate)")

        guard bitrate != .auto else {
            logger.debug("Bitrate is .auto, running bitrate test...")
            let testedBitrate = try await testBitrate(with: settingBitrate.rawValue)
            logger.debug("Bitrate test result: \(testedBitrate)")
            return testedBitrate
        }
        logger.debug("Using fixed bitrate: \(bitrate.rawValue)")
        return bitrate.rawValue
    }

    private func testBitrate(with testSize: Int) async throws -> Int {
        precondition(testSize > 0, "testSize must be greater than zero")

        let userSession = Container.shared.currentUserSession()!

        let testStartTime = Date()
        _ = try await userSession.client.send(Paths.getBitrateTestBytes(size: testSize))
        let testDuration = Date().timeIntervalSince(testStartTime)
        let testSizeBits = Double(testSize * 8)
        let testBitrate = testSizeBits / testDuration

        /// Exceeding 500 mbps will produce an invalid URL
        return min(Int(testBitrate), PlaybackBitrate.max.rawValue)
    }
}

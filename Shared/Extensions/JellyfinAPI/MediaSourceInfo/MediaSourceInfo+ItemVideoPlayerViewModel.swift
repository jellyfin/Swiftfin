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

// MARK: - Audio Stream Scoring Constants

private enum AudioStreamScoring {
    // Base quality scores for different codec types
    static let highQualityLossyScore = 25 // EAC-3 without Atmos
    static let standardLossyScore = 20 // AC-3
    static let directPlayableLossyScore = 15 // AAC (direct-playable on iOS)
    static let compressedLossyScore = 10 // DTS
    static let losslessBaseScore = 8 // TrueHD without Atmos
    static let dtsHDScore = 7 // DTS-HD
    static let flacAlacScore = 6 // FLAC/ALAC
    static let penalizedScore = 1 // TrueHD with Atmos (transcoding required)

    // Preference bonuses
    static let atmosBonus = 100 // Playable Atmos gets highest priority
    static let losslessBonus = 50 // Lossless preference boost

    // Tie-breaker bonuses
    static let defaultStreamBonus = 5 // Default stream preference
    static let firstStreamBonus = 2 // First stream tie-breaker
}

extension MediaSourceInfo {
    /// Determines the best audio stream index based on user preferences and stream characteristics.
    func selectBestAudioStreamIndex() -> Int {
        let logger = Container.shared.logService()
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        guard !audioStreams.isEmpty else {
            logger.debug("No audio streams found.")
            return -1
        }

        let preferAtmos = Defaults[Defaults.Keys.VideoPlayer.preferDolbyAtmos]
        let preferLossless = Defaults[Defaults.Keys.VideoPlayer.preferLosslessAudio]
        let firstAudioStreamIndex = audioStreams.first?.index

        let scoredStreams = audioStreams.map { stream -> (stream: MediaStream, score: Int) in
            var score = 0
            let codec = stream.codec?.lowercased() ?? ""

            // 1. Base Quality Score (Prioritizing high-quality, direct-playable lossy codecs by default)
            switch codec {
            // High-quality lossy
            case AudioCodec.eac3.rawValue where !stream.isDolbyAtmos:
                score = AudioStreamScoring.highQualityLossyScore
            case AudioCodec.ac3.rawValue:
                score = AudioStreamScoring.standardLossyScore
            case AudioCodec.aac.rawValue:
                score = AudioStreamScoring.directPlayableLossyScore // Higher than DTS because it's direct-playable
            case AudioCodec.dts.rawValue:
                score = AudioStreamScoring.compressedLossyScore
            // Lossless (lower base score, will be boosted by preference)
            case AudioCodec.truehd.rawValue where !stream.isDolbyAtmos:
                score = AudioStreamScoring.losslessBaseScore
            case AudioCodec.dts_hd.rawValue:
                score = AudioStreamScoring.dtsHDScore
            case AudioCodec.flac.rawValue, AudioCodec.alac.rawValue:
                score = AudioStreamScoring.flacAlacScore
            // Penalized
            case AudioCodec.truehd.rawValue where stream.isDolbyAtmos:
                score = AudioStreamScoring.penalizedScore
            default:
                score = 0
            }

            // 2. Preference Bonuses
            if preferAtmos && stream.isDolbyAtmos && codec == AudioCodec.eac3.rawValue {
                score += AudioStreamScoring.atmosBonus // Playable Atmos is king
            }
            if preferLossless && stream.isLossless {
                score += AudioStreamScoring.losslessBonus // Boost makes lossless codecs win
            }

            // 3. Tie-breaker Bonuses
            if stream.isDefault == true {
                score += AudioStreamScoring.defaultStreamBonus
            }
            if stream.index == firstAudioStreamIndex {
                score += AudioStreamScoring.firstStreamBonus
            }

            return (stream, score)
        }

        // Find the stream with the highest score
        let bestStream = scoredStreams.max { $0.score < $1.score }?.stream

        if let bestStream = bestStream, let index = bestStream.index {
            logger.debug(
                "Best audio stream selected: Index \(index), Codec: \(bestStream.codec ?? "N/A"), Score: \(scoredStreams.first { $0.stream.index == index }?.score ?? 0)"
            )
            return index
        }

        // Fallback logic
        if let defaultIndex = defaultAudioStreamIndex {
            logger.debug("Falling back to default audio stream with index \(defaultIndex).")
            return defaultIndex
        } else if let firstAudio = audioStreams.first, let firstIndex = firstAudio.index {
            logger.debug("Falling back to first available audio stream with index \(firstIndex).")
            return firstIndex
        } else {
            logger.debug("No suitable audio stream found.")
            return -1
        }
    }

    func videoPlayerViewModel(with item: BaseItemDto, playSessionID: String, audioStreamIndex: Int? = nil) throws -> VideoPlayerViewModel {

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

        let logger = Container.shared.logService()
        let videoStreams = mediaStreams?.filter { $0.type == .video } ?? []
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        let subtitleStreams = mediaStreams?.filter { $0.type == .subtitle } ?? []

        logger.debug("Available audio tracks:")
        for stream in audioStreams {
            logger.debug("- Index: \(stream.index ?? -1), Codec: \(stream.codec ?? "N/A"), Profile: \(stream.profile ?? "N/A")")
        }

        // Use provided audio stream index or apply custom selection logic
        let selectedAudioStreamIndex: Int

        if let audioStreamIndex = audioStreamIndex {
            selectedAudioStreamIndex = audioStreamIndex
            logger.debug("Using provided audio stream index: \(selectedAudioStreamIndex)")
        } else {
            selectedAudioStreamIndex = selectBestAudioStreamIndex()
        }

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

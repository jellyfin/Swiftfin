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

private extension MediaStream {
    /// Determines if the audio stream is lossless.
    var isLossless: Bool {
        guard type == .audio, let codec = codec?.lowercased() else { return false }
        // List of known lossless audio codecs
        let losslessCodecs: [String] = [
            AudioCodec.flac.rawValue,
            AudioCodec.alac.rawValue,
            AudioCodec.truehd.rawValue,
            AudioCodec.dts_hd.rawValue, // dts-hd ma, dts-hd hra
        ]
        // Check if the codec is in our lossless list or is a PCM format
        return losslessCodecs.contains(where: codec.contains) || codec.starts(with: "pcm")
    }

    var isDolbyAtmos: Bool {
        guard let codec = codec?.lowercased() else { return false }
        let isEAC3 = codec == AudioCodec.eac3.rawValue
        let isTrueHD = codec == AudioCodec.truehd.rawValue
        let hasAtmosProfile = profile?.lowercased().contains("atmos") ?? false
        let hasAtmosTag = codecTag?.lowercased() == "ec-3"

        return (isEAC3 && (hasAtmosProfile || hasAtmosTag)) || (isTrueHD && hasAtmosProfile)
    }
}

extension MediaSourceInfo {
    /// Determines the best audio stream index based on user preferences and stream characteristics.
    func selectBestAudioStreamIndex() -> Int {
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        guard !audioStreams.isEmpty else {
            print("[MediaSourceInfo] No audio streams found.")
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
            case AudioCodec.eac3.rawValue where !stream.isDolbyAtmos: score = 25
            case AudioCodec.ac3.rawValue: score = 20
            case AudioCodec.aac.rawValue: score = 15 // Higher than DTS because it's direct-playable
            case AudioCodec.dts.rawValue: score = 10
            // Lossless (lower base score, will be boosted by preference)
            case AudioCodec.truehd.rawValue where !stream.isDolbyAtmos: score = 8
            case AudioCodec.dts_hd.rawValue: score = 7
            case AudioCodec.flac.rawValue, AudioCodec.alac.rawValue: score = 6
            // Penalized
            case AudioCodec.truehd.rawValue where stream.isDolbyAtmos: score = 1
            default: score = 0
            }

            // 2. Preference Bonuses
            if preferAtmos && stream.isDolbyAtmos && codec == AudioCodec.eac3.rawValue {
                score += 100 // Playable Atmos is king
            }
            if preferLossless && stream.isLossless {
                score += 50 // Boost makes lossless codecs win
            }

            // 3. Tie-breaker Bonuses
            if stream.isDefault ?? false { score += 5 }
            if stream.index == firstAudioStreamIndex { score += 2 }

            return (stream, score)
        }

        // Find the stream with the highest score
        let bestStream = scoredStreams.max { $0.score < $1.score }?.stream

        if let bestStream = bestStream, let index = bestStream.index {
            print(
                "[MediaSourceInfo] Best audio stream selected: Index \(index), Codec: \(bestStream.codec ?? "N/A"), Score: \(scoredStreams.first { $0.stream.index == index }?.score ?? 0)"
            )
            return index
        }

        // Fallback logic
        if let defaultIndex = defaultAudioStreamIndex {
            print("[MediaSourceInfo] Falling back to default audio stream with index \(defaultIndex).")
            return defaultIndex
        } else if let firstAudio = audioStreams.first, let firstIndex = firstAudio.index {
            print("[MediaSourceInfo] Falling back to first available audio stream with index \(firstIndex).")
            return firstIndex
        } else {
            print("[MediaSourceInfo] No suitable audio stream found.")
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

        let videoStreams = mediaStreams?.filter { $0.type == .video } ?? []
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        let subtitleStreams = mediaStreams?.filter { $0.type == .subtitle } ?? []

        print("[MediaSourceInfo] Available audio tracks:")
        for stream in audioStreams {
            print("[MediaSourceInfo] - Index: \(stream.index ?? -1), Codec: \(stream.codec ?? "N/A"), Profile: \(stream.profile ?? "N/A")")
        }

        // Use provided audio stream index or apply custom selection logic
        let selectedAudioStreamIndex: Int

        if let audioStreamIndex = audioStreamIndex {
            selectedAudioStreamIndex = audioStreamIndex
            print("[MediaSourceInfo] Using provided audio stream index: \(selectedAudioStreamIndex)")
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

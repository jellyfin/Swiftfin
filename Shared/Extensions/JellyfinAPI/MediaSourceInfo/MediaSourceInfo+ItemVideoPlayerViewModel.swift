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

    /// Determines the best audio stream index based on codec priority
    func selectBestAudioStreamIndex() -> Int {
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []

        guard !audioStreams.isEmpty else {
            print("[MediaSourceInfo] No audio streams found.")
            return -1
        }

        let hasAtmos: (MediaStream) -> Bool = { $0.profile?.lowercased().contains("atmos") ?? false }
        let isDTSHD: (MediaStream)
            -> Bool = { $0.profile?.lowercased().contains("dts-hd") ?? false || $0.profile?.lowercased().contains("dts:x") ?? false }

        // Priority order:
        // 1. E-AC3 Atmos
        // 2. TrueHD (non-Atmos)
        // 3. DTS-HD
        // 4. TrueHD Atmos
        // 5. Default audio stream
        // 6. First available stream

        if let eac3AtmosStream = audioStreams.first(where: { $0.codec?.lowercased() == "eac3" && hasAtmos($0) }),
           let index = eac3AtmosStream.index
        {
            print("[MediaSourceInfo] Prioritizing E-AC3 Atmos stream with index \(index).")
            return index
        } else if let trueHDStream = audioStreams.first(where: { $0.codec?.lowercased() == "truehd" && !hasAtmos($0) }),
                  let index = trueHDStream.index
        {
            print("[MediaSourceInfo] Prioritizing TrueHD stream with index \(index).")
            return index
        } else if let dtsHDStream = audioStreams.first(where: { isDTSHD($0) }),
                  let index = dtsHDStream.index
        {
            print("[MediaSourceInfo] Prioritizing DTS-HD stream with index \(index).")
            return index
        } else if let trueHDAtmosStream = audioStreams.first(where: { $0.codec?.lowercased() == "truehd" && hasAtmos($0) }),
                  let index = trueHDAtmosStream.index
        {
            print("[MediaSourceInfo] Prioritizing TrueHD Atmos stream with index \(index).")
            return index
        } else if let defaultIndex = defaultAudioStreamIndex {
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

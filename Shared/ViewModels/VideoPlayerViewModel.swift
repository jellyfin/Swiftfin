//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import VLCUI
import UIKit

final class VideoPlayerViewModel: ViewModel {
    
    let playbackURL: URL
    let hlsPlaybackURL: URL
    let item: BaseItemDto
    let mediaSource: MediaSourceInfo
    let playSessionID: String
    let videoStreams: [MediaStream]
    let audioStreams: [MediaStream]
    let subtitleStreams: [MediaStream]
    let selectedAudioStreamIndex: Int
    let selectedSubtitleStreamIndex: Int
    let chapters: [ChapterInfo.FullInfo]
    let streamType: StreamType
    
    var vlcVideoPlayerConfiguration: VLCVideoPlayer.Configuration {
        let configuration = VLCVideoPlayer.Configuration(url: playbackURL)
        configuration.autoPlay = true
        configuration.startTime = .seconds(max(0, item.startTimeSeconds - Defaults[.VideoPlayer.resumeOffset]))
        configuration.audioIndex = .absolute(selectedAudioStreamIndex)
        configuration.subtitleIndex = .absolute(selectedSubtitleStreamIndex)
        configuration.subtitleSize = .absolute(Defaults[.VideoPlayer.Subtitle.subtitleSize])

        if let font = UIFont(name: Defaults[.VideoPlayer.Subtitle.subtitleFontName], size: 0) {
            configuration.subtitleFont = .absolute(font)
        }

        configuration.playbackChildren = subtitleStreams
            .filter { $0.deliveryMethod == .external }
            .compactMap(\.asPlaybackChild)

        return configuration
    }
    
    init(
        playbackURL: URL,
        hlsPlaybackURL: URL,
        item: BaseItemDto,
        mediaSource: MediaSourceInfo,
        playSessionID: String,
        videoStreams: [MediaStream],
        audioStreams: [MediaStream],
        subtitleStreams: [MediaStream],
        selectedAudioStreamIndex: Int,
        selectedSubtitleStreamIndex: Int,
        chapters: [ChapterInfo.FullInfo],
        streamType: StreamType
    ) {
        self.item = item
        self.mediaSource = mediaSource
        self.playSessionID = playSessionID
        self.playbackURL = playbackURL
        self.hlsPlaybackURL = hlsPlaybackURL
        self.videoStreams = videoStreams
        self.audioStreams = audioStreams
        self.subtitleStreams = subtitleStreams
            .adjustExternalSubtitleIndexes(audioStreamCount: audioStreams.count)
        self.selectedAudioStreamIndex = selectedAudioStreamIndex
        self.selectedSubtitleStreamIndex = selectedSubtitleStreamIndex
        self.chapters = chapters
        self.streamType = streamType
        super.init()
    }
    
    func chapter(from seconds: Int) -> ChapterInfo.FullInfo? {
        chapters.first(where: { $0.secondsRange.contains(seconds) })
    }
    
    func constructHLSPlaybackURL() throws -> URL {
        
        guard let itemID = item.id, let mediaSourceID = mediaSource.id else { throw JellyfinAPIError("Unable to construct HLS stream: invalid item ID or media source ID") }

//        let hlsStreamBuilder = DynamicHlsAPI.getMasterHlsVideoPlaylistWithRequestBuilder(
//            itemId: itemID,
//            mediaSourceId: mediaSourceID,
//            _static: true,
//            tag: mediaSource.eTag,
//            playSessionId: playSessionID,
//            segmentContainer: "mp4",
//            minSegments: 2,
//            deviceId: UIDevice.vendorUUIDString,
//            audioCodec: mediaSource.audioStreams?
//                .compactMap(\.codec)
//                .joined(separator: ","),
//            breakOnNonKeyFrames: true,
//            requireAvc: false,
//            transcodingMaxAudioChannels: 6,
//            videoCodec: mediaSource.videoStreams?
//                .compactMap(\.codec)
//                .joined(separator: ","),
//            videoStreamIndex: mediaSource.videoStreams?.first?.index,
//            enableAdaptiveBitrateStreaming: true
//        )
//
//        var hlsStreamComponents = URLComponents(string: hlsStreamBuilder.URLString)!
////        hlsStreamComponents.addQueryItem(name: "api_key", value: SessionManager.main.currentLogin.user.accessToken)
//
//        return hlsStreamComponents.url!
        return URL(string: "/")!
    }
}

extension VideoPlayerViewModel: Equatable {
    
    static func == (lhs: VideoPlayerViewModel, rhs: VideoPlayerViewModel) -> Bool {
        lhs.item == rhs.item &&
        lhs.playbackURL == rhs.playbackURL
    }
}

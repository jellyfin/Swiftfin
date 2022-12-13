//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI
import UIKit

extension MediaSourceInfo {

    func videoPlayerViewModel(with item: BaseItemDto, playSessionID: String) throws -> VideoPlayerViewModel {
        
        let userSession = Container.userSession.callAsFunction()
        let playbackURL: URL
        let streamType: StreamType
        
        if let transcodingURL, !Defaults[.Experimental.forceDirectPlay] {
            guard let fullTranscodeURL = URL(string: "".appending(transcodingURL)) else { throw JellyfinAPIError("Unable to construct transcoded url") }
            playbackURL = fullTranscodeURL
            streamType = .transcode
        } else {
//            playbackURL = VideosAPI.getVideoStreamWithRequestBuilder(
//                itemId: item.id!,
//                _static: true,
//                tag: item.etag,
//                playSessionId: playSessionID,
//                mediaSourceId: self.id
//            ).url
            
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
            
            playbackURL = userSession.client.fullURL(with: videoStreamRequest)
            streamType = .direct
        }

        let videoStreams = mediaStreams?.filter({ $0.type == .video }) ?? []
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        let subtitleStreams = mediaStreams?.filter { $0.type == .subtitle } ?? []

//        let hlsStreamBuilder = DynamicHlsAPI.getMasterHlsVideoPlaylistWithRequestBuilder(
//            itemId: itemID,
//            mediaSourceId: mediaSourceID,
//            _static: true,
//            tag: eTag,
//            playSessionId: playSessionID,
//            segmentContainer: "mp4",
//            minSegments: 2,
//            deviceId: UIDevice.vendorUUIDString,
//            audioCodec: audioStreams
//                .compactMap(\.codec)
//                .joined(separator: ","),
//            breakOnNonKeyFrames: true,
//            requireAvc: false,
//            transcodingMaxAudioChannels: 6,
//            videoCodec: videoStreams
//                .compactMap(\.codec)
//                .joined(separator: ","),
//            videoStreamIndex: videoStreams.first?.index,
//            enableAdaptiveBitrateStreaming: true
//        )

//        var hlsStreamComponents = URLComponents(string: hlsStreamBuilder.URLString)!
//        hlsStreamComponents.addQueryItem(name: "api_key", value: SessionManager.main.currentLogin.user.accessToken)
        var hlsStreamComponents = URLComponents(string: "/")!
        
        return .init(
            playbackURL: playbackURL,
            hlsPlaybackURL: hlsStreamComponents.url!,
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

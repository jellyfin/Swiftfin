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

extension MediaSourceInfo {

    // TODO: Better throwing handling
    func itemVideoPlayerViewModel(with item: BaseItemDto, playSessionID: String) throws -> VideoPlayerViewModel {
        let playbackURL: URL
        let streamType: StreamType
        
        if let transcodingUrl, !Defaults[.Experimental.forceDirectPlay] {
            guard let fullTranscodeURL = URL(string: SessionManager.main.currentLogin.server.currentURI.appending(transcodingUrl)) else { throw JellyfinAPIError("Unable to construct transcoded url") }
            playbackURL = fullTranscodeURL
            streamType = .transcode
        } else {
            playbackURL = VideosAPI.getVideoStreamWithRequestBuilder(
                itemId: item.id!,
                _static: true,
                tag: item.etag,
                playSessionId: playSessionID,
                mediaSourceId: self.id
            ).url
            
            streamType = .direct
        }

        let videoStream = mediaStreams?.filter { $0.type == .video }.first ?? .init()
        let audioStreams = mediaStreams?.filter { $0.type == .audio } ?? []
        let subtitleStreams = mediaStreams?.filter { $0.type == .subtitle } ?? []

        return VideoPlayerViewModel(
            playbackURL: playbackURL,
            item: item,
            videoStream: videoStream,
            audioStreams: audioStreams,
            subtitleStreams: subtitleStreams,
            selectedAudioStreamIndex: defaultAudioStreamIndex ?? -1,
            selectedSubtitleStreamIndex: defaultSubtitleStreamIndex ?? -1,
            chapters: item.fullChapterInfo,
            streamType: streamType
        )
    }
}

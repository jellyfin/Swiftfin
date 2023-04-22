//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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
            guard let fullTranscodeURL = URL(string: "".appending(transcodingURL))
            else { throw JellyfinAPIError("Unable to construct transcoded url") }
            playbackURL = fullTranscodeURL
            streamType = .transcode
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

            playbackURL = userSession.client.fullURL(with: videoStreamRequest)
            streamType = .direct
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
            streamType: streamType
        )
    }
}

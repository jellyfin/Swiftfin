//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Combine
import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

extension BaseItemDto {
    
//    func createVideoPlayerViewModel(with mediaSource: MediaSourceInfo) -> AnyPublisher<VideoPlayerViewModel, Error> {
//        
//        let builder = DeviceProfileBuilder()
//        // TODO: fix bitrate settings
//        let tempOverkillBitrate = 360_000_000
//        builder.setMaxBitrate(bitrate: tempOverkillBitrate)
//        let profile = builder.buildProfile()
//        let segmentContainer = Defaults[.Experimental.usefmp4Hls] ? "mp4" : "ts"

//        let playbackInfoRequest = GetPostedPlaybackInfoRequest(
////            userId: "123abc",
//            userId: "123abc",
//            maxStreamingBitrate: tempOverkillBitrate,
//            deviceProfile: profile
//        )
//
//        return MediaInfoAPI.getPostedPlaybackInfo(
//            itemId: self.id!,
////            userId: "123abc",
//            userId: "123abc",
//            maxStreamingBitrate: tempOverkillBitrate,
//            getPostedPlaybackInfoRequest: playbackInfoRequest
//        )
//        .tryMap { response in
////            guard let matchingMediaSource = response.mediaSources?.first(where: { $0.eTag == mediaSource.eTag && $0.id == mediaSource.id }) else { throw JellyfinAPIError("Matching media source not in playback info") }
//            guard let playSessionID = response.playSessionId else { throw JellyfinAPIError("Play session ID not in playback info request") }
//
//            return try mediaSource.videoPlayerViewModel(with: self, playSessionID: playSessionID)
//        }
//        .eraseToAnyPublisher()
//    }
}

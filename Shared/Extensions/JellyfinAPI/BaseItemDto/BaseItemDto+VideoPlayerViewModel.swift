//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Factory
import Foundation
import JellyfinAPI

extension BaseItemDto {

    func videoPlayerViewModel(with mediaSource: MediaSourceInfo) async throws -> VideoPlayerViewModel {

        let currentVideoPlayerType = Defaults[.VideoPlayer.videoPlayerType]
        // TODO: fix bitrate settings
        let tempOverkillBitrate = 360_000_000
        let profile = DeviceProfile.build(for: currentVideoPlayerType, maxBitrate: tempOverkillBitrate)

        let userSession = Container.userSession()

        let playbackInfo = PlaybackInfoDto(deviceProfile: profile)
        let playbackInfoParameters = Paths.GetPostedPlaybackInfoParameters(
            userID: userSession.user.id,
            maxStreamingBitrate: tempOverkillBitrate
        )

        let request = Paths.getPostedPlaybackInfo(
            itemID: self.id!,
            parameters: playbackInfoParameters,
            playbackInfo
        )

        let response = try await userSession.client.send(request)

        guard let matchingMediaSource = response.value.mediaSources?
            .first(where: { $0.eTag == mediaSource.eTag && $0.id == mediaSource.id })
        else { throw JellyfinAPIError("Matching media source not in playback info") }

        return try matchingMediaSource.videoPlayerViewModel(with: self, playSessionID: response.value.playSessionID!)
    }
}

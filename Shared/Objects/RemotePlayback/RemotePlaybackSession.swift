//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

@MainActor
protocol RemoteSession: MediaPlayerProxy {

    var route: RemotePlaybackRoute { get }
    var deviceName: String? { get }

    func connect(startingAt seconds: Duration) async throws
    func disconnect()

    func supports(_ button: VideoPlayerActionButton) -> Bool
}

extension RemoteSession {

    func supports(_ button: VideoPlayerActionButton) -> Bool {
        true
    }
}

@MainActor
protocol CastContentSession: RemoteSession {}

@MainActor
protocol RemotePlaybackSession: RemoteSession {

    func setTrack(type: MediaStreamType, index: Int?)
    func setBitrate(_ bitrate: PlaybackBitrate)
}

extension RemotePlaybackSession {

    func setTrack(type: MediaStreamType, index: Int?) {}
    func setBitrate(_ bitrate: PlaybackBitrate) {}
}

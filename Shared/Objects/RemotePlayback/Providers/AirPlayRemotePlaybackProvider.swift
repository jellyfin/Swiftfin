//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults

@MainActor
final class AirPlayRemotePlaybackProvider: RemotePlaybackProvider {

    let route: RemotePlaybackRoute = .airPlay
    let kind: RemotePlaybackProviderKind = .systemPicker

    weak var manager: MediaPlayerManager?

    init(manager: MediaPlayerManager?) {
        self.manager = manager
    }

    var isAvailable: Bool {
        #if os(tvOS)
        false
        #else
        Defaults[.VideoPlayer.videoPlayerType] == .avPlayer
        #endif
    }

    var isActive: Bool {
        manager?.remote.state?.type == .airPlay
    }

    let targets: [RemotePlaybackTarget] = []

    func refresh() {}

    func isActive(_ target: RemotePlaybackTarget) -> Bool {
        false
    }

    func makeSession(for target: RemotePlaybackTarget) -> (any RemotePlaybackSession)? {
        nil
    }
}

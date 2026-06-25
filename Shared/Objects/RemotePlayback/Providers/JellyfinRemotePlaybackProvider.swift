//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

// TODO: Implement. Will need Socket.

@MainActor
final class JellyfinRemotePlaybackProvider: RemotePlaybackProvider {

    let route: RemotePlaybackRoute = .jellyfin
    let kind: RemotePlaybackProviderKind = .deviceList

    weak var manager: MediaPlayerManager?

    init(manager: MediaPlayerManager?) {
        self.manager = manager
    }

    var isAvailable: Bool {
        false
    }

    let isActive: Bool = false

    let targets: [RemotePlaybackTarget] = []

    func refresh() {}

    func isActive(_ target: RemotePlaybackTarget) -> Bool {
        false
    }

    func makeSession(for target: RemotePlaybackTarget) -> (any RemotePlaybackSession)? {
        nil
    }
}

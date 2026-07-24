//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

@MainActor
protocol RemotePlaybackProvider: AnyObject {

    var route: RemotePlaybackRoute { get }
    var kind: RemotePlaybackProviderKind { get }
    var isAvailable: Bool { get }
    var isActive: Bool { get }
    var targets: [RemotePlaybackTarget] { get }

    func refresh()
    func isActive(_ target: RemotePlaybackTarget) -> Bool
    func makeSession(for target: RemotePlaybackTarget) -> (any RemotePlaybackSession)?
}

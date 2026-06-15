//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

@MainActor
protocol RemotePlaybackSession: MediaPlayerProxy {

    var route: RemotePlaybackRoute { get }
    var deviceName: String? { get }

    func connect(startingAt seconds: Duration) async throws
    func disconnect()
}

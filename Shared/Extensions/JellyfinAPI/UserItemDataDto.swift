//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI

extension Container {

    var userItemCache: Factory<HashCache<UserItemDataDto>> {
        self { @MainActor in HashCache<UserItemDataDto>() }
            .singleton
    }
}

protocol WithUserData {
    var userData: UserItemDataDto? { get set }
}

extension UserItemDataDto {

    var playbackPosition: Duration? {
        get {
            guard let playbackPositionTicks else { return nil }
            return Duration.ticks(playbackPositionTicks)
        }
        set {
            playbackPositionTicks = newValue?.ticks
        }
    }
}

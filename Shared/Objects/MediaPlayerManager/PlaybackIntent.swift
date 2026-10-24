//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

@MainActor
struct PlaybackIntent {

    let entry: ItemEntry
    var queue: (any MediaPlayerQueue)?
    var configuration: MediaPlaybackConfiguration

    var item: BaseItemDto {
        entry.snapshot
    }

    var mediaSource: MediaSourceInfo? {
        configuration.mediaSource(in: item)
    }

    init(item: BaseItemDto, queue: (any MediaPlayerQueue)? = nil) {
        self.init(item: item, configuration: .init(), queue: queue)
    }

    init(item: BaseItemDto, configuration: MediaPlaybackConfiguration, queue: (any MediaPlayerQueue)? = nil) {
        self.entry = SharedBaseItem(wrappedValue: item).entry
        self.queue = queue
        self.configuration = configuration
    }
}

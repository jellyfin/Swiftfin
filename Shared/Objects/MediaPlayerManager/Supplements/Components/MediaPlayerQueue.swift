//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Observation

@MainActor
protocol MediaPlayerQueue: AnyObject, Observable, MediaSessionObserver {

    var hasNextItem: Bool { get }
    var hasPreviousItem: Bool { get }

    var nextItem: PlaybackIntent? { get }
    var previousItem: PlaybackIntent? { get }
}

extension MediaPlayerQueue {

    var hasNextItem: Bool {
        nextItem != nil
    }

    var hasPreviousItem: Bool {
        previousItem != nil
    }
}

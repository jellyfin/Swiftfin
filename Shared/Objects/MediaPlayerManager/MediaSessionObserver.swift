//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine

/// Observes playback until the returned token is cancelled.
/// The token retains the observer. Observers must hold the mediaSession weakly.
@MainActor
protocol MediaSessionObserver: AnyObject {

    func observe(_ mediaSession: MediaSession) -> AnyCancellable
}

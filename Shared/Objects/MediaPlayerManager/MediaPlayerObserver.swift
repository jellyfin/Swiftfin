//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

// TODO: have delegate-like functions for callbacks, rather
// than observers implementing internal publishers

/// A protocol for observers of a `MediaPlayerManager`
protocol MediaPlayerObserver {

    var manager: MediaPlayerManager? { get set }
}

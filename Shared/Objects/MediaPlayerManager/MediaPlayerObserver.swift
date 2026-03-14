//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// A protocol for observers of a `MediaPlayerManager`.
///
/// - Important: The `manager` property should most likely be a `weak`
/// reference to avoid retain cycles. The observer itself should be
/// strongly held by a `MediaPlayerItem` or other parent object or view.
@MainActor
protocol MediaPlayerObserver {

    var manager: MediaPlayerManager? { get set }
}

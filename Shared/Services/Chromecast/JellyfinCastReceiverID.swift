//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Jellyfin Cast receiver application IDs (Google Cast sender discovery).
///
/// Parity: `jellyfin-web` and server playback settings use the same values for
/// stable vs unstable receivers. `Info.plist` includes `_F007D354._googlecast._tcp`
/// under `NSBonjourServices` for stable discovery.
enum JellyfinCastReceiverID {

    /// Production Jellyfin Cast web receiver (stable channel).
    static let stable = "F007D354"

    /// Experimental receiver (unstable / master); use only when aligned with server or web client.
    static let unstable = "6F511C87"
}

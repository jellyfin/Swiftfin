//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

/// Google Cast Web Receiver application IDs registered by the Jellyfin project.
///
/// These IDs identify which Cast receiver app runs on the Chromecast device when
/// a session is started. They are registered at cast.google.com/publish and map to
/// the hosted Jellyfin Web Receiver at https://github.com/jellyfin/jellyfin-chromecast.
enum JellyfinCastReceiverID {

    /// Production Web Receiver — use this in release builds.
    static let stable = "F007D354"

    /// Development Web Receiver built from the main branch — use this for testing unreleased receiver changes.
    static let unstable = "6F511C87"
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Testing

struct ChromecastTests {

    @Test
    func receiverIDsAreNotEmpty() {
        #expect(!JellyfinCastReceiverID.stable.isEmpty)
        #expect(!JellyfinCastReceiverID.unstable.isEmpty)
    }

    @Test
    func receiverIDsAreDistinct() {
        #expect(JellyfinCastReceiverID.stable != JellyfinCastReceiverID.unstable)
    }

    @Test
    func stableReceiverIDMatchesKnownValue() {
        // Sourced from jellyfin-web chromecastPlayer/plugin.js.
        // If this fails, the ID was changed upstream — verify intentional before updating.
        #expect(JellyfinCastReceiverID.stable == "F007D354")
        #expect(JellyfinCastReceiverID.unstable == "6F511C87")
    }
}

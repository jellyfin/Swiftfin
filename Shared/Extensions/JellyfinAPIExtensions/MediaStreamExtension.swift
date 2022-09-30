//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import VLCUI

extension MediaStream {

    func externalURL(base: String) -> URL? {
        var base = base
        while base.last == Character("/") {
            base.removeLast()
        }
        guard let deliveryURL = deliveryUrl else { return nil }
        return URL(string: base + deliveryURL)
    }

    var asPlaybackChild: VLCVideoPlayer.PlaybackChild? {
        guard let url = externalURL(base: SessionManager.main.currentLogin.server.currentURI) else { return nil }
        return .init(
            url: url,
            type: .subtitle,
            enforce: false
        )
    }
}

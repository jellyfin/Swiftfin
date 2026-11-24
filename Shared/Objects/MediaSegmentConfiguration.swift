//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

@DefaultDecodable
struct MediaSegmentConfiguration: Hashable, Storable, WithDefaultValue {

    var actions: [MediaSegmentType: MediaSegmentAction] = [.intro: .ask, .outro: .ask]
    var skipDelay: Int = 5
    var repeatMode: MediaSegmentRepeatMode = .once

    subscript(type: MediaSegmentType) -> MediaSegmentAction {
        get {
            actions[type] ?? .off
        }
        set {
            actions[type] = newValue
        }
    }

    static let `default` = MediaSegmentConfiguration()
}

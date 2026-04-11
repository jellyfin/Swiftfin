//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension MediaSourceInfo: Displayable {

    var displayTitle: String {
        name ?? .emptyDash
    }
}

extension MediaSourceInfo {

    var audioStreams: [MediaStream]? {
        mediaStreams?.filter { $0.type == .audio }
    }

    var subtitleStreams: [MediaStream]? {
        mediaStreams?.filter { $0.type == .subtitle }
    }

    var videoStreams: [MediaStream]? {
        mediaStreams?.filter { $0.type == .video }
    }
}

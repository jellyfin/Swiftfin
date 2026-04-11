//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActivityLogEntry: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        .square
    }

    var displayTitle: String {
        name ?? L10n.unknown
    }

    var unwrappedIDHashOrZero: Int {
        id?.hashValue ?? 0
    }

    var systemImage: String {
        "text.document"
    }

    func transform(image: Image) -> some View {
        image
    }
}

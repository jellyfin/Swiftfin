//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI
import SwiftUI

extension RemoteImageInfo: @retroactive Identifiable, Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        .portrait
    }

    var displayTitle: String {
        providerName ?? L10n.unknown
    }

    var unwrappedIDHashOrZero: Int {
        id
    }

    var subtitle: String? {
        language
    }

    var systemImage: String {
        "photo"
    }

    public var id: Int {
        hashValue
    }

    func transform(image: Image) -> some View {
        image
    }
}

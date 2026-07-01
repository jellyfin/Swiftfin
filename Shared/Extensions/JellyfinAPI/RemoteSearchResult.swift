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

extension RemoteSearchResult: Poster {

    var preferredPosterDisplayType: PosterDisplayType {
        .portrait // Some exceptions (E.G. Music Videos)
    }

    var systemImage: String {
        "questionmark"
    }

    func portraitImageSources(
        environment: Empty
    ) -> [ImageSource] {
        [ImageSource(url: imageURL?.url)]
    }
}

extension RemoteSearchResult: Displayable {

    var displayTitle: String {
        name ?? L10n.unknown
    }
}

extension RemoteSearchResult: @retroactive Identifiable {

    public var id: Int {
        hashValue
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

extension MediaSegmentType: Displayable, @retroactive Defaults.Serializable {

    var displayTitle: String {
        switch self {
        case .commercial:
            L10n.commercial
        case .preview:
            L10n.preview
        case .recap:
            L10n.recap
        case .outro:
            L10n.outro
        case .intro:
            L10n.intro
        case .unknown:
            L10n.unknown
        }
    }
}

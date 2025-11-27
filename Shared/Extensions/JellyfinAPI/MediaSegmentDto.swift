//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI

extension MediaSegmentType: Displayable, _DefaultsSerializable {

    // TODO: Localize
    var displayTitle: String {
        switch self {
        case .commercial:
            return L10n.commercial
        case .preview:
            return L10n.preview
        case .recap:
            return L10n.recap
        case .outro:
            return L10n.outro
        case .intro:
            return L10n.intro
        case .unknown:
            return L10n.unknown
        }
    }
}

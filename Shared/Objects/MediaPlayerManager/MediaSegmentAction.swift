//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults

enum MediaSegmentAction: String, Displayable, CaseIterable, Defaults.Serializable {

    case ignore
    case ask
    case skip

    var localizedString: String {
        switch self {
        case .ignore: return L10n.mediaSegmentActionIgnore
        case .ask: return L10n.mediaSegmentActionAsk
        case .skip: return L10n.mediaSegmentActionSkip
        }
    }

    var displayTitle: String {
        localizedString
    }
}

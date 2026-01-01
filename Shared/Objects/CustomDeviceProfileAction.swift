//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum CustomDeviceProfileAction: String, CaseIterable, Displayable, Storable {

    case add
    case replace

    var displayTitle: String {
        switch self {
        case .add:
            return L10n.add
        case .replace:
            return L10n.replace
        }
    }
}

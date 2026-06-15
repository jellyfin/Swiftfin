//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

#if os(iOS)
enum PermissionStatus: Equatable {
    case authorized
    case denied
    case unknown

    var displayTitle: String {
        switch self {
        case .authorized:
            L10n.allowed
        case .denied:
            L10n.unauthorized
        case .unknown:
            L10n.unknown
        }
    }
}
#endif

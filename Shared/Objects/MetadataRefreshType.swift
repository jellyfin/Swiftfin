//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum MetadataRefreshType: CaseIterable, Displayable {

    case scan
    case missing
    case all

    var displayTitle: String {
        switch self {
        case .scan:
            L10n.scanForNewAndUpdatedFiles
        case .missing:
            L10n.searchForMissingMetadata
        case .all:
            L10n.replaceAllMetadata
        }
    }

    var replaceMetadata: Bool {
        switch self {
        case .scan, .missing:
            false
        case .all:
            true
        }
    }

    /// For now, this covers both `metadataRefreshMode` and `imageRefreshMode`
    /// - Split into 2 func if we ever need differing logic for each.
    var metadataRefreshMode: MetadataRefreshMode {
        switch self {
        case .scan:
            .default
        case .missing, .all:
            .fullRefresh
        }
    }

    /// For now, this covers both `regenerateTrickplay` and `replaceImages`
    /// - Split into 2 func if we ever need differing logic for each.
    func replaceElements(_ selection: Bool) -> Bool {
        switch self {
        case .scan:
            false
        case .missing, .all:
            selection
        }
    }
}

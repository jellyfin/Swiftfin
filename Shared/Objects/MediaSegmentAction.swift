//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

enum MediaSegmentAction: String, Displayable, Storable, SupportedCaseIterable {

    case off
    case ask
    case skip

    /// Actions available to segments that are too short to skip automatically.
    static var supportedCases: [MediaSegmentAction] {
        [.off, .ask]
    }

    var displayTitle: String {
        switch self {
        case .off:
            L10n.off
        case .ask:
            L10n.ask
        case .skip:
            L10n.skip
        }
    }

    var description: String {
        switch self {
        case .off:
            L10n.mediaSegmentOffDescription
        case .ask:
            L10n.mediaSegmentAskDescription
        case .skip:
            L10n.mediaSegmentSkipDescription
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

/// The placement of the main tab bar on tvOS.
enum TabBarPlacement: String, CaseIterable, Displayable, Storable {

    /// A leading sidebar that expands when focused
    case sidebar

    /// A horizontally centered bar along the top
    case centered

    var displayTitle: String {
        switch self {
        case .sidebar:
            L10n.sidebar
        case .centered:
            L10n.centered
        }
    }
}

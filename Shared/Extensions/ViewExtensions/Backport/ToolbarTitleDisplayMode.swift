//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum ToolbarTitleDisplayMode {

    case automatic
    case inline
    case inlineLarge
    case large

    var navigationBarTitleDisplayMode: NavigationBarItem.TitleDisplayMode {
        switch self {
        case .automatic: .automatic
        case .inline: .inline
        case .inlineLarge, .large:
            #if os(iOS)
            .large
            #else
            .automatic
            #endif
        }
    }

    @available(iOS 17, tvOS 17, *)
    var swiftUIValue: SwiftUI.ToolbarTitleDisplayMode {
        switch self {
        case .automatic: .automatic
        case .inline: .inline
        case .inlineLarge:
            #if os(iOS)
            .inlineLarge
            #else
            .automatic
            #endif
        case .large:
            #if os(iOS)
            .large
            #else
            .automatic
            #endif
        }
    }
}

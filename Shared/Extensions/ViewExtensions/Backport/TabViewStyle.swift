//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum TabViewStyle {

    case automatic
    case page
    case sidebarAdaptable
    case tabBarOnly

    var swiftUIValue: any SwiftUI.TabViewStyle {
        switch self {
        case .automatic: .automatic
        case .page: .page
        case .sidebarAdaptable:
            if #available(iOS 18, tvOS 18, *) {
                .sidebarAdaptable
            } else {
                .automatic
            }
        case .tabBarOnly:
            if #available(iOS 18, tvOS 18, *) {
                .tabBarOnly
            } else {
                .automatic
            }
        }
    }
}

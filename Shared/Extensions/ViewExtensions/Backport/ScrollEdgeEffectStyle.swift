//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

enum ScrollEdgeEffectStyle: Hashable, Sendable {

    case automatic
    case hard
    case soft

    @available(iOS 26.0, tvOS 26.0, *)
    var swiftUIValue: SwiftUI.ScrollEdgeEffectStyle {
        switch self {
        case .automatic: .automatic
        case .hard: .hard
        case .soft: .soft
        }
    }
}

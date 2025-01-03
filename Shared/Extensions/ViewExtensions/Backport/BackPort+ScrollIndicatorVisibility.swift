//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

extension Backport {

    enum ScrollIndicatorVisibility {

        case automatic
        case visible
        case hidden
        case never

        @available(iOS 16, tvOS 16, *)
        var supportedValue: SwiftUI.ScrollIndicatorVisibility {
            switch self {
            case .automatic: .automatic
            case .visible: .visible
            case .hidden: .hidden
            case .never: .never
            }
        }
    }
}

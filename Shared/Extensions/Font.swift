//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Font {

    var uiFont: UIFont? {
        switch self {
        #if os(iOS)
        case .largeTitle:
            UIFont.preferredFont(forTextStyle: .largeTitle)
        #endif
        case .title:
            UIFont.preferredFont(forTextStyle: .title1)
        case .title2:
            UIFont.preferredFont(forTextStyle: .title2)
        case .title3:
            UIFont.preferredFont(forTextStyle: .title3)
        case .headline:
            UIFont.preferredFont(forTextStyle: .headline)
        case .subheadline:
            UIFont.preferredFont(forTextStyle: .subheadline)
        case .callout:
            UIFont.preferredFont(forTextStyle: .callout)
        case .caption:
            UIFont.preferredFont(forTextStyle: .caption1)
        case .caption2:
            UIFont.preferredFont(forTextStyle: .caption2)
        case .footnote:
            UIFont.preferredFont(forTextStyle: .footnote)
        case .body:
            UIFont.preferredFont(forTextStyle: .body)
        default:
            nil
        }
    }
}

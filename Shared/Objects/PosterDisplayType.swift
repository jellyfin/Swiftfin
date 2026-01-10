//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

#if os(iOS)
private let landscapeMaxWidth: CGFloat = 300
private let portraitMaxWidth: CGFloat = 200
#else
private let landscapeMaxWidth: CGFloat = 500
private let portraitMaxWidth: CGFloat = 500
#endif

enum PosterDisplayType: String, CaseIterable, Displayable, Storable {

    enum Size: CaseIterable, Displayable, Storable {

        case small
        case medium

        var displayTitle: String {
            switch self {
            case .small:
                "Small"
            case .medium:
                "Medium"
            }
        }

        var quality: Int? {
            90
        }

        func width(for displayType: PosterDisplayType) -> CGFloat? {
            switch displayType {
            case .landscape:
                landscapeMaxWidth
            case .portrait, .square:
                portraitMaxWidth
            }
        }
    }

    case landscape
    case portrait
    case square

    var displayTitle: String {
        switch self {
        case .landscape:
            L10n.landscape
        case .portrait:
            L10n.portrait
        case .square:
            "Square"
        }
    }
}

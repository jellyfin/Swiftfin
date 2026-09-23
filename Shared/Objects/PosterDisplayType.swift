//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum PosterDisplayType: String, CaseIterable, Displayable, Storable, SystemImageable {

    enum Size: Equatable, Hashable, Storable {

        case extraSmall
        case small
        case medium
        case custom(width: CGFloat)

        var quality: Int? {
            90
        }

        func width(
            for displayType: PosterDisplayType,
            presentation: ViewLayout.Presentation = .current
        ) -> CGFloat? {
            switch self {
            case .extraSmall:
                switch displayType {
                case .landscape:
                    110
                case .portrait, .square:
                    60
                }

            case .small:
                if presentation == .large {
                    500
                } else {
                    // Standard presentations use smaller thumbnails than large presentations.
                    displayType == .landscape ? 300 : 200
                }

            case .medium:
                500

            case let .custom(width):
                width
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
            L10n.square
        }
    }

    var systemImage: String {
        switch self {
        case .landscape:
            "rectangle.fill"
        case .portrait:
            "rectangle.portrait.fill"
        case .square:
            "square.fill"
        }
    }
}

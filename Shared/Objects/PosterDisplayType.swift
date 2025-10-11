//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

enum PosterDisplayType: String, CaseIterable, Displayable, Storable, SystemImageable {

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
            switch self {
            default: 90
            }
        }

        func width(for displayType: PosterDisplayType) -> CGFloat? {
            switch displayType {
            case .landscape:
                switch self {
                case .small:
                    200
                case .medium:
                    300
                }
            case .portrait, .square:
                switch self {
                case .small:
                    200
                case .medium:
                    400
                }
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

// TODO: remove after library views support all types
extension PosterDisplayType: SupportedCaseIterable {

    static var supportedCases: [PosterDisplayType] {
        [.landscape, .portrait]
    }
}

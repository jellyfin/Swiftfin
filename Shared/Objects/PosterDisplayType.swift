//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation

enum PosterDisplayType: String, CaseIterable, Displayable, Storable, SystemImageable {

    enum Size {
        case small
        case medium
        case original

        var quality: Int? {
            switch self {
            case .original: nil
            default: 90
            }
        }
    }

    case landscape
    case portrait
    case square

    func width(for size: Size) -> CGFloat? {
        switch self {
        case .landscape:
            switch size {
            case .small:
                200
            case .medium:
                300
            case .original:
                nil
            }
        case .portrait, .square:
            switch size {
            case .small:
                200
            case .medium:
                400
            case .original:
                nil
            }
        }
    }

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

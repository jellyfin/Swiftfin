//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

enum PlaybackResolution: Int, CaseIterable, Displayable, Storable {

    case max = 0
    case p2160 = 2160
    case p1440 = 1440
    case p1080 = 1080
    case p720 = 720
    case p480 = 480
    case p360 = 360
    case p240 = 240

    // swiftlint:disable:next hard_coded_display_string
    var displayTitle: String {
        switch self {
        case .max:
            return L10n.original
        default:
            guard rawValue > 0 else { return L10n.unknown }
            return "\(rawValue.description)p"
        }
    }

    var codecProfile: CodecProfile? {
        guard rawValue > 0 else { return nil }

        return CodecProfile(
            type: .video,
            conditions: {
                ProfileCondition(
                    condition: .lessThanEqual,
                    isRequired: true,
                    property: .height,
                    value: rawValue.description
                )
            }
        )
    }
}

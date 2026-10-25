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
            return L10n.maximum
        default:
            guard rawValue > 0 else { return L10n.unknown }

            return "\(rawValue.description)p"
        }
    }

    func codecProfile(for mediaSource: MediaSourceInfo?) -> CodecProfile? {
        guard rawValue > 0 else { return nil }

        let videoStream = mediaSource?.mediaStreams?.first { $0.type == .video }

        // Jellyfin's bitrate normalizer can discard MaxHeight when it selects a width.
        // Bound both dimensions, preserving the source aspect ratio when it is known.
        let maxWidth: Int = if let width = videoStream?.width, let height = videoStream?.height, width > 0, height > 0 {
            Swift.max(1, Int((Double(width) * Double(rawValue) / Double(height)).rounded(.up)))
        } else {
            rawValue * 16 / 9
        }

        return CodecProfile(
            type: .video,
            conditions: {
                ProfileCondition(
                    condition: .lessThanEqual,
                    isRequired: true,
                    property: .width,
                    value: maxWidth.description
                )

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

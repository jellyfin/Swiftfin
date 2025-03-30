//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension PlaylistViewModel {

    enum PlaylistType: String, Displayable, Hashable, CaseIterable, Identifiable {

        case audio = "Audio"
        case book = "Book"
        case photo = "Photo"
        case video = "Video"
        case unknown = "Unknown"

        var displayTitle: String {
            switch self {
            case .audio:
                return L10n.audio
            case .book:
                return L10n.books
            case .photo:
                return L10n.images
            case .video:
                return L10n.video
            case .unknown:
                return L10n.unknown
            }
        }

        var id: String {
            rawValue
        }
    }
}

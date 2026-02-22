//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

extension PersonKind: Displayable, SupportedCaseIterable {
    var displayTitle: String {
        switch self {
        case .unknown:
            L10n.unknown
        case .actor:
            L10n.actor
        case .director:
            L10n.director
        case .composer:
            L10n.composer
        case .writer:
            L10n.writer
        case .guestStar:
            L10n.guestStar
        case .producer:
            L10n.producer
        case .conductor:
            L10n.conductor
        case .lyricist:
            L10n.lyricist
        case .arranger:
            L10n.arranger
        case .engineer:
            L10n.engineer
        case .mixer:
            L10n.mixer
        case .remixer:
            L10n.remixer
        case .creator:
            L10n.creator
        case .artist:
            L10n.artist
        case .albumArtist:
            L10n.albumArtist
        case .author:
            L10n.author
        case .illustrator:
            L10n.illustrator
        case .penciller:
            L10n.penciller
        case .inker:
            L10n.inker
        case .colorist:
            L10n.colorist
        case .letterer:
            L10n.letterer
        case .coverArtist:
            L10n.coverArtist
        case .editor:
            L10n.editor
        case .translator:
            L10n.translator
        }
    }

    static var supportedCases: [PersonKind] {
        [.actor, .director, .writer, .producer]
    }
}

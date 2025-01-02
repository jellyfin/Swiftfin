//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

// TODO: No longer needed in 10.9+
public enum PersonKind: String, Codable, CaseIterable {
    case unknown = "Unknown"
    case actor = "Actor"
    case director = "Director"
    case composer = "Composer"
    case writer = "Writer"
    case guestStar = "GuestStar"
    case producer = "Producer"
    case conductor = "Conductor"
    case lyricist = "Lyricist"
    case arranger = "Arranger"
    case engineer = "Engineer"
    case mixer = "Mixer"
    case remixer = "Remixer"
    case creator = "Creator"
    case artist = "Artist"
    case albumArtist = "AlbumArtist"
    case author = "Author"
    case illustrator = "Illustrator"
    case penciller = "Penciller"
    case inker = "Inker"
    case colorist = "Colorist"
    case letterer = "Letterer"
    case coverArtist = "CoverArtist"
    case editor = "Editor"
    case translator = "Translator"
}

// TODO: Still needed in 10.9+
extension PersonKind: Displayable {
    var displayTitle: String {
        switch self {
        case .unknown:
            return L10n.unknown
        case .actor:
            return L10n.actor
        case .director:
            return L10n.director
        case .composer:
            return L10n.composer
        case .writer:
            return L10n.writer
        case .guestStar:
            return L10n.guestStar
        case .producer:
            return L10n.producer
        case .conductor:
            return L10n.conductor
        case .lyricist:
            return L10n.lyricist
        case .arranger:
            return L10n.arranger
        case .engineer:
            return L10n.engineer
        case .mixer:
            return L10n.mixer
        case .remixer:
            return L10n.remixer
        case .creator:
            return L10n.creator
        case .artist:
            return L10n.artist
        case .albumArtist:
            return L10n.albumArtist
        case .author:
            return L10n.author
        case .illustrator:
            return L10n.illustrator
        case .penciller:
            return L10n.penciller
        case .inker:
            return L10n.inker
        case .colorist:
            return L10n.colorist
        case .letterer:
            return L10n.letterer
        case .coverArtist:
            return L10n.coverArtist
        case .editor:
            return L10n.editor
        case .translator:
            return L10n.translator
        }
    }
}

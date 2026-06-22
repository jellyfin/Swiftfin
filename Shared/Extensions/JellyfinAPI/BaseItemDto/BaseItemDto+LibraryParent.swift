//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension BaseItemDto: LibraryParent {

    struct Grouping: Codable, Displayable, Hashable, Identifiable, Storable {

        let displayTitle: String
        let id: String

        static let episodes = Grouping(displayTitle: L10n.episodes, id: "episodes")
        static let series = Grouping(displayTitle: L10n.series, id: "series")
    }

    var libraryType: BaseItemKind? {
        type
    }

    var groupings: (defaultSelection: Grouping, elements: [Grouping])? {
        switch collectionType {
        case .tvshows:
            (.series, [.episodes, .series])
        default:
            nil
        }
    }

    var supportedItemTypes: [BaseItemKind] {
        supportedItemTypes(for: nil)
    }

    func supportedItemTypes(for grouping: Grouping?) -> [BaseItemKind] {
        switch (collectionType, libraryType) {
        case (_, .folder):
            BaseItemKind.supportedCases
                .appending([.folder, .collectionFolder])
        case (.movies, _):
            [.movie]
        case (.tvshows, _):
            grouping == .episodes ? [.episode] : [.series]
        case (.music, _):
            [.audio, .musicAlbum, .musicArtist]
        case (.boxsets, _):
            BaseItemKind.supportedCases
        default:
            BaseItemKind.supportedCases
        }
    }

    var isRecursiveCollection: Bool {
        isRecursiveCollection(for: nil)
    }

    func isRecursiveCollection(for grouping: Grouping?) -> Bool {
        guard let collectionType, libraryType != .userView else { return true }

        if grouping == .episodes {
            return true
        }

        return ![.tvshows, .boxsets].contains(collectionType)
    }
}

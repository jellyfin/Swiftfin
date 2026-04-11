//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

extension BaseItemDto: LibraryParent {

    var libraryType: BaseItemKind? {
        type
    }

    var supportedItemTypes: [BaseItemKind] {
        guard let collectionType else { return [] }

        switch (collectionType, libraryType) {
        case (_, .folder):
            return BaseItemKind.supportedCases
                .appending([.folder, .collectionFolder])
        case (.movies, _):
            return [.movie]
        case (.tvshows, _):
            return [.series]
        case (.boxsets, _):
            return BaseItemKind.supportedCases
        default:
            return BaseItemKind.supportedCases
        }
    }

    var isRecursiveCollection: Bool {
        guard let collectionType, libraryType != .userView else { return true }

        return ![.tvshows, .boxsets].contains(collectionType)
    }
}

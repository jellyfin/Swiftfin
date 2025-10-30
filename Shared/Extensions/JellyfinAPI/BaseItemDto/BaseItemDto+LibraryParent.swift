//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI

// extension BaseItemDto: LibraryParent {
//
//    var libraryType: BaseItemKind? {
//        type
//    }
//
//    var supportedItemTypes: [BaseItemKind] {
//        guard let collectionType else { return [] }
//
//        switch (collectionType, libraryType) {
//        case (_, .folder):
//            return BaseItemKind.supportedCases
//                .appending([.folder, .collectionFolder])
//        case (.movies, _):
//            return [.movie]
//        case (.tvshows, _):
//            return [.series]
//        case (.boxsets, _):
//            return BaseItemKind.supportedCases
//        default:
//            return BaseItemKind.supportedCases
//        }
//    }
//
//    var isRecursiveCollection: Bool {
//        guard let collectionType, libraryType != .userView else { return true }
//
//        return ![.tvshows, .boxsets].contains(collectionType)
//    }
// }

// struct BasicLibraryGrouping: Displayable, Hashable, Identifiable, Storable {
//    let displayTitle: String
//    let id: String
// }

protocol LibraryGrouping: Displayable, Equatable, Hashable, Identifiable<String>, Storable {
    var id: String { get }
}

struct _TitledLibraryParent: _LibraryParent {

    let displayTitle: String
    let libraryID: String
}

extension BaseItemDto: _LibraryParent {

    struct Grouping: LibraryGrouping {

        let displayTitle: String
        let id: String

        static let episodes = Grouping(displayTitle: L10n.episodes, id: "episodes")
        static let series = Grouping(displayTitle: L10n.series, id: "series")
    }

    var libraryID: String {
        id ?? "unknown"
    }

    var groupings: (defaultSelection: Grouping, elements: [Grouping])? {
        switch collectionType {
        case .tvshows:
            let episodes = Grouping(displayTitle: L10n.episodes, id: "episodes")
            let series = Grouping(displayTitle: L10n.series, id: "series")
            return (series, [episodes, series])
        default:
            return nil
        }
    }

    func _supportedItemTypes(for grouping: Grouping?) -> [BaseItemKind] {
        if self.collectionType == .folders {
            return BaseItemKind.supportedCases
                .appending([.folder, .collectionFolder])
        }

        if collectionType == .tvshows {
            if let grouping, grouping == .episodes {
                return [.episode]
            } else {
                return [.series]
            }
        }

        return BaseItemKind.supportedCases
    }

    func _isRecursiveCollection(for grouping: Grouping?) -> Bool {
        guard let collectionType, type != .userView else { return true }

        if let grouping, grouping == .episodes {
            return true
        }

        return ![.tvshows, .boxsets].contains(collectionType)
    }
}

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
        static let folders = Grouping(displayTitle: L10n.folders, id: "folders")
        static let items = Grouping(displayTitle: L10n.items, id: "items")
        static let seasons = Grouping(displayTitle: L10n.seasons, id: "seasons")
        static let series = Grouping(displayTitle: L10n.series, id: "series")
    }

    var libraryType: BaseItemKind? {
        type
    }

    var groupings: (defaultSelection: Grouping, elements: [Grouping])? {
        if isFolderCollection {
            return (.folders, [])
        }

        return switch collectionType {
        case .tvshows:
            (.series, [.episodes, .seasons, .series, .folders])
        case .movies, .musicvideos, .homevideos:
            (.items, [.items, .folders])
        default:
            nil
        }
    }

    var supportedItemTypes: [BaseItemKind] {
        supportedItemTypes(for: nil)
    }

    /// Folder libraries browse direct children, including nested folders.
    /// A folder that directly contains a standalone photo is resolved by
    /// the server as a `PhotoAlbum` instead of a `Folder` (#2431), so it
    /// is treated as a folder collection here as well.
    var isFolderCollection: Bool {
        libraryType == .folder ||
            libraryType == .photoAlbum ||
            ((libraryType == .collectionFolder || libraryType == .userView) && (collectionType ?? .folders) == .folders)
    }

    func supportedItemTypes(for grouping: Grouping?) -> [BaseItemKind] {
        if isFolderCollection || grouping == .folders {
            if libraryType == .userView, collectionType == .movies || collectionType == .tvshows {
                return [.collectionFolder]
            }
            return BaseItemKind.supportedCases.appending([.folder, .collectionFolder, .photoAlbum])
        }

        return switch (collectionType, libraryType) {
        case (.boxsets, _):
            BaseItemKind.supportedCases

        case (_, .channel), (_, .liveTvChannel), (_, .tvChannel):
            [.liveTvProgram]

        case (.movies, _):
            [.movie]

        case (.music, _):
            [.audio, .musicAlbum, .musicArtist]

        case (.tvshows, _):
            switch grouping {
            case .episodes:
                [.episode]
            case .seasons:
                [.season]
            default:
                [.series]
            }

        default:
            BaseItemKind.supportedCases
        }
    }

    var isRecursiveCollection: Bool {
        isRecursiveCollection(for: nil)
    }

    func isRecursiveCollection(for grouping: Grouping?) -> Bool {
        guard !isFolderCollection, grouping != .folders else { return false }
        guard let collectionType, libraryType != .userView else { return true }

        if grouping == .episodes || grouping == .seasons {
            return true
        }

        return ![.tvshows, .boxsets].contains(collectionType)
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

enum HomePosterGroup: String, Codable, CaseIterable, Displayable, Identifiable {

    case resume
    case nextUp
    case recentlyAdded
    case recentlyPlayed
    case recommended
    case latestInLibrary

    var id: String {
        "home-\(rawValue)"
    }

    var displayTitle: String {
        switch self {
        case .resume: L10n.continue
        case .nextUp: L10n.nextUp
        case .recentlyAdded: L10n.recentlyAdded
        case .recentlyPlayed: L10n.recentlyPlayed
        case .recommended: L10n.recommended
        case .latestInLibrary: L10n.libraries
        }
    }

    var defaultSettings: PosterGroupSettings {
        switch self {
        case .resume: .resume
        case .nextUp, .recentlyAdded, .recentlyPlayed: .default
        case .recommended, .latestInLibrary: .liveTV
        }
    }

    var libraryStyleKey: StoredValues.Key<LibraryStyle> {
        let key = StoredValues.Keys.User.libraryStyle(
            id: id,
            default: .init(
                displayType: .grid,
                posterDisplayType: defaultSettings.displayType,
                listColumnCount: 1,
                posterSize: defaultSettings.size.posterSize
            )
        )

        migrateLegacySettings(to: key)
        return key
    }

    @MainActor
    func makeGroup<Library: PagingLibrary>(
        library: Library,
        id: String? = nil,
        viewContext: ViewContext = .init()
    ) -> PosterGroup<Library> where Library.Element: LibraryElement, Library.Element: Poster {
        PosterGroup(
            id: id ?? self.id,
            library: library,
            posterDisplayType: defaultSettings.displayType,
            posterSize: defaultSettings.size.posterSize,
            libraryStyleKey: libraryStyleKey,
            _viewContext: viewContext
        )
    }

    private func migrateLegacySettings(to key: StoredValues.Key<LibraryStyle>) {
        guard key.ownerID.isNotEmpty else { return }

        let existingStyle: LibraryStyle? = try? AnyStoredData.fetch(
            ownerID: key.ownerID,
            field: key.field ?? key.name,
            key: key.name
        )
        guard existingStyle == nil else { return }

        let legacyLayout: LegacyLayout? = try? AnyStoredData.fetch(
            ownerID: key.ownerID,
            field: "setting-homeLayout",
            key: "setting-homeLayout"
        )
        guard let settings = legacyLayout?.posters[self] else { return }

        var style = key.defaultValue()
        style.posterDisplayType = settings.displayType
        style.posterSize = settings.size.posterSize
        StoredValues[key] = style
    }

    private struct LegacyLayout: Codable {

        let posters: [HomePosterGroup: PosterGroupSettings]
    }
}

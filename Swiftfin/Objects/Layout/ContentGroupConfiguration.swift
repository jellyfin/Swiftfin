//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation
import JellyfinAPI

struct ContentGroupConfiguration: Codable, Hashable, Identifiable, Displayable, SystemImageable {

    let id: String
    var title: String?
    var source: ContentGroupSource

    init(
        id: String = UUID().uuidString,
        title: String? = nil,
        source: ContentGroupSource
    ) {
        self.id = id
        self.title = title.nilIfEmpty
        self.source = source
    }

    var displayTitle: String {
        title.nilIfEmpty ?? source.displayTitle
    }

    var systemImage: String {
        source.systemImage
    }

    static func library(
        id: String = UUID().uuidString,
        title: String? = nil,
        reference: LibraryReference?,
        filters: ItemFilterCollection = .default,
        poster: PosterGroupSettings = .default
    ) -> Self {
        .init(
            id: id,
            title: title,
            source: .library(.init(
                library: reference,
                filters: filters,
                poster: poster
            ))
        )
    }

    static func resume(
        id: String = UUID().uuidString,
        title: String? = nil,
        parent: LibraryReference? = nil,
        searchTerm: String? = nil,
        itemTypes: [BaseItemKind] = [.episode, .movie, .video],
        poster: PosterGroupSettings = .resume
    ) -> Self {
        .init(
            id: id,
            title: title,
            source: .resume(.init(
                parent: parent,
                searchTerm: searchTerm,
                itemTypes: itemTypes,
                poster: poster
            ))
        )
    }

    static func nextUp(
        id: String = UUID().uuidString,
        title: String? = nil,
        library: LibraryReference? = nil,
        series: ItemReference? = nil,
        enableRewatching: Bool = false,
        maxDays: Int? = NextUpGroupConfiguration.defaultDays,
        poster: PosterGroupSettings = .default
    ) -> Self {
        .init(
            id: id,
            title: title,
            source: .nextUp(.init(
                library: library,
                series: series,
                enableRewatching: enableRewatching,
                maxDays: maxDays,
                poster: poster
            ))
        )
    }

    static func liveTV(
        id: String = UUID().uuidString,
        title: String? = nil,
        element: LiveTVElement,
        poster: PosterGroupSettings = .liveTV
    ) -> Self {
        .init(
            id: id,
            title: title,
            source: .liveTV(.init(element: element, poster: poster))
        )
    }

    static func genres(
        id: String = UUID().uuidString,
        title: String? = nil,
        parent: LibraryReference? = nil,
        searchTerm: String? = nil,
        itemTypes: [BaseItemKind] = []
    ) -> Self {
        .init(
            id: id,
            title: title,
            source: .genres(.init(
                parent: parent,
                searchTerm: searchTerm,
                itemTypes: itemTypes
            ))
        )
    }
}

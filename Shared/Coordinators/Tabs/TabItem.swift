//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: selected icon
@MainActor
struct TabItem: Identifiable, Hashable {

    let content: AnyView
    let id: String
    let title: String
    let systemImage: String
    let labelStyle: any LabelStyle

    init(
        id: String,
        title: String,
        systemImage: String,
        labelStyle: some LabelStyle = .titleAndIcon,
        @ViewBuilder content: () -> some View
    ) {
        self.content = AnyView(content())
        self.id = id
        self.title = title
        self.systemImage = systemImage
        self.labelStyle = labelStyle
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.id == rhs.id
    }
}

extension TabItem {

    static var home: TabItem {
        TabItem(
            id: "home",
            title: L10n.home,
            systemImage: "house"
        ) {
            // Bruno: tvOS gets the Bruno streamer home; iOS keeps stock Home (and stays compiling).
            #if os(tvOS)
            BrunoHomeView()
            #else
            HomeView()
            #endif
        }
    }

    static var media: TabItem {
        TabItem(
            id: "media",
            title: L10n.media,
            systemImage: "rectangle.stack.fill"
        ) {
            PagingLibraryView(library: UserViewLibrary())
                .if(UIDevice.isTV) { view in
                    view.toolbar(.hidden, for: .navigationBar)
                }
        }
    }

    #if os(tvOS)
    // Bruno: Movies / TV Shows get a branded surface — a cinematic spotlight hero for the category
    // atop the full A–Z poster grid (BrunoMediaView), replacing the bare stock library grid.
    static var movies: TabItem {
        TabItem(
            id: "movies",
            title: L10n.movies,
            systemImage: "film"
        ) {
            BrunoMediaView(itemType: .movie, heroEyebrow: "Featured Film")
        }
    }

    static var tvShows: TabItem {
        TabItem(
            id: "tvShows",
            title: L10n.tvShowsCapitalized,
            systemImage: "tv"
        ) {
            BrunoMediaView(itemType: .series, heroEyebrow: "Featured Series")
        }
    }

    // Bruno: the curated-collections hub — a category row + one capped shelf per group
    // (Directors, Decades, Studios, …), each with "Show all" -> the full grid (roadmap §3).
    static var collections: TabItem {
        TabItem(
            id: "collections",
            title: L10n.collections,
            systemImage: "square.stack.fill"
        ) {
            BrunoCollectionsView()
        }
    }

    // Bruno: the owner's kids content may be split across separate Jellyfin libraries (e.g.
    // "Kids Movies" + "Kids Shows"). BrunoKidsView merges them and adds All / Movies / TV filters.
    static var kids: TabItem {
        TabItem(
            id: "kids",
            title: L10n.kids,
            systemImage: "teddybear.fill"
        ) {
            BrunoKidsView()
        }
    }
    #endif

    static var search: TabItem {
        // Bruno tvOS IA: Search/Settings are trailing utility tabs — icon-only, no text.
        #if os(tvOS)
        TabItem(
            id: "search",
            title: L10n.search,
            systemImage: "magnifyingglass",
            labelStyle: .iconOnly
        ) {
            SearchView()
        }
        #else
        TabItem(
            id: "search",
            title: L10n.search,
            systemImage: "magnifyingglass"
        ) {
            SearchView()
        }
        #endif
    }

    static var settings: TabItem {
        #if os(tvOS)
        TabItem(
            id: "settings",
            title: L10n.settings,
            systemImage: "gearshape",
            labelStyle: .iconOnly
        ) {
            SettingsView()
        }
        #else
        TabItem(
            id: "settings",
            title: L10n.settings,
            systemImage: "gearshape"
        ) {
            SettingsView()
        }
        #endif
    }
}

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
struct TabItem: Displayable, @MainActor Identifiable, @MainActor Hashable {

    let content: AnyView
    let displayTitle: String
    let id: String
    let systemImage: String
    let labelStyle: any LabelStyle

    init(
        id: String,
        title: String,
        systemImage: String,
        @ViewBuilder content: () -> some View
    ) {
        self.init(
            id: id,
            title: title,
            systemImage: systemImage,
            labelStyle: .titleAndIcon,
            content: content
        )
    }

    init(
        id: String,
        title: String,
        systemImage: String,
        labelStyle: some LabelStyle,
        @ViewBuilder content: () -> some View
    ) {
        self.content = AnyView(content())
        self.id = id
        self.displayTitle = title
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

    static var adminDashboard: TabItem {
        TabItem(
            id: "admin-dashboard",
            title: L10n.dashboard,
            systemImage: "server.rack"
        ) {
            #if os(iOS)
            AdminDashboardView()
            #else
            EmptyView()
            #endif
        }
    }

    static func contentGroup(
        provider: some ContentGroupProvider
    ) -> TabItem {
        TabItem(
            id: provider.id,
            title: provider.displayTitle,
            systemImage: "house.fill"
        ) {
            ContentGroupView(provider: provider)
        }
    }

    static func item(id: String, displayTitle: String) -> TabItem {
        let item = BaseItemDto(id: id, name: displayTitle)

        return TabItem(
            id: id,
            title: displayTitle,
            systemImage: item.systemImage
        ) {
            ItemView(item: item)
        }
    }

    static func library(
        title: String,
        systemName: String,
        filters: ItemFilterCollection
    ) -> TabItem {
        TabItem(
            id: "library-\(UUID().uuidString)",
            title: title,
            systemImage: systemName
        ) {
            PagingLibraryView(
                library: ItemLibrary(
                    parent: BaseItemDto(name: title),
                    filters: filters
                )
            )
            .if(UIDevice.isTV) { view in
                view.toolbar(.hidden, for: .navigationBar)
            }
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

    static var liveTV: TabItem {
        TabItem(
            id: "live-tv",
            title: L10n.liveTV,
            systemImage: "play.tv"
        ) {
            NavigationRoute.liveTV.destination
        }
    }

    static var search: TabItem {
        TabItem(
            id: "search",
            title: L10n.search,
            systemImage: "magnifyingglass"
        ) {
            SearchView()
        }
    }

    static var settings: TabItem {
        TabItem(
            id: "settings",
            title: L10n.settings,
            systemImage: "gearshape"
        ) {
            SettingsView()
        }
    }
}

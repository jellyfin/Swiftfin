//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
enum TabItemSetting: @preconcurrency Identifiable {

    case adminDashboard
    case contentGroup(ContentGroupProviderSetting)
    case item(id: String)
    case liveTV
    case media
    case search
    case settings

    var id: String {
        switch self {
        case .adminDashboard:
            "admin-dashboard"
        case let .contentGroup(provider):
            provider.provider.id
        case let .item(id):
            id
        case .liveTV:
            "live-tv"
        case .media:
            "media"
        case .search:
            "search"
        case .settings:
            "settings"
        }
    }

    var item: TabItem {
        switch self {
        case .adminDashboard:
            #if os(iOS)
            .adminDashboard
            #endif
        case let .contentGroup(provider):
            .contentGroup(provider: provider.provider)
        case let .item(id):
            .item(id: id)
        case .liveTV:
            .liveTV
        case .media:
            .media
        case .search:
            .search
        case .settings:
            .settings
        }
    }
}

@MainActor
struct TabItem: Displayable, Identifiable, SystemImageable {

    let content: AnyView
    let displayTitle: String
    let id: String
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
        self.displayTitle = title
        self.systemImage = systemImage
        self.labelStyle = labelStyle
    }
}

extension TabItem {

    static let adminDashboard = TabItem(
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

    static func contentGroup(
        provider: some _ContentGroupProvider
    ) -> TabItem {
        TabItem(
            id: provider.id,
            title: provider.displayTitle,
            systemImage: provider.systemImage
        ) {
            ContentGroupView(provider: provider)
//            ContentGroupShimView(id: provider.id)
        }
    }

    static func item(
        id: String
    ) -> TabItem {
        TabItem(
            id: id,
            title: "Test",
            systemImage: "figure.walk"
        ) {
            ItemView(
                item: .init(
                    id: id,
                    type: .movie
                )
            )
        }
    }

    static func library(
        title: String,
        systemName: String,
        filters: ItemFilterCollection
    ) -> TabItem {

        let id = "library-\(UUID().uuidString)"

        return TabItem(
            id: id,
            title: title,
            systemImage: systemName
        ) {
            let library = PagingItemLibrary(
                parent: .init(name: title),
                filters: filters
            )

            PagingLibraryView(library: library)
        }
    }

    static let liveTV = TabItem(
        id: "live-tv",
        title: L10n.liveTV,
        systemImage: "play.tv"
    ) {
        NavigationRoute.liveTV.destination
    }

    static let media = TabItem(
        id: "media",
        title: L10n.media,
        systemImage: "rectangle.stack.fill"
    ) {
//        PagingLibraryView(library: MediaLibrary())
        MediaView()
    }

    static let search = TabItem(
        id: "search",
        title: L10n.search,
        systemImage: "magnifyingglass"
    ) {
        SearchView()
    }

    static let settings = TabItem(
        id: "settings",
        title: L10n.settings,
        systemImage: "gearshape",
        labelStyle: .iconOnly
    ) {
        SettingsView()
    }
}

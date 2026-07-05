//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

#if os(iOS)
import FactoryKit
#endif

@MainActor
enum TabItemSetting: Identifiable, Hashable, Storable {

    case adminDashboard
    case contentGroup(ContentGroupProviderSetting)
    case item(id: String, displayTitle: String)
    case liveTV
    case library(title: String, systemName: String, filters: ItemFilterCollection)
    case media
    case search
    case settings

    var id: String {
        switch self {
        case .adminDashboard:
            "admin-dashboard"
        case let .contentGroup(provider):
            provider.provider.id
        case let .item(id, _):
            id
        case .liveTV:
            "live-tv"
        case let .library(title, _, filters):
            "library-\(title)-\(filters.hashValue)"
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
            #else
            .settings
            #endif
        case let .contentGroup(provider):
            .contentGroup(provider: provider.provider)
        case let .item(id, displayTitle):
            .item(id: id, displayTitle: displayTitle)
        case .liveTV:
            .liveTV
        case let .library(title, systemName, filters):
            .library(title: title, systemName: systemName, filters: filters)
        case .media:
            .media
        case .search:
            .search
        case .settings:
            .settings
        }
    }
}

// TODO: selected icon
@MainActor
struct TabItem: Identifiable, Hashable {

    let content: AnyView
    let id: String
    let title: String
    let systemImage: String
    let labelStyle: any LabelStyle

    var displayTitle: String {
        title
    }

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
            PrimaryTabRootView {
                ContentGroupView(provider: provider)
            }
        }
    }

    static func item(id: String, displayTitle: String) -> TabItem {
        let item = BaseItemDto(id: id, name: displayTitle)

        return TabItem(
            id: id,
            title: displayTitle,
            systemImage: item.systemImage
        ) {
            PrimaryTabRootView {
                ItemView(item: item)
            }
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
            PrimaryTabRootView {
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
    }

    static var media: TabItem {
        TabItem(
            id: "media",
            title: L10n.media,
            systemImage: "rectangle.stack.fill"
        ) {
            PrimaryTabRootView {
                PagingLibraryView(library: UserViewLibrary())
                    .if(UIDevice.isTV) { view in
                        view.toolbar(.hidden, for: .navigationBar)
                    }
            }
        }
    }

    static var liveTV: TabItem {
        TabItem(
            id: "live-tv",
            title: L10n.liveTV,
            systemImage: "play.tv"
        ) {
            PrimaryTabRootView {
                NavigationRoute.liveTV.destination
            }
        }
    }

    static var search: TabItem {
        TabItem(
            id: "search",
            title: L10n.search,
            systemImage: "magnifyingglass"
        ) {
            PrimaryTabRootView {
                SearchView()
            }
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

private struct PrimaryTabRootView<Content: View>: View {

    @Router
    private var router

    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        #if os(iOS)
        content
            .topBarTrailing {
                settingsButton
            }
        #else
        content
        #endif
    }

    #if os(iOS)
    @Injected(\.currentUserSession)
    private var userSession

    @ViewBuilder
    private var settingsButton: some View {
        if router.isRootOfPath,
           let userSession
        {
            SettingsBarButton(
                server: userSession.server,
                user: userSession.user
            ) {
                router.route(to: .settings)
            }
        }
    }
    #endif
}

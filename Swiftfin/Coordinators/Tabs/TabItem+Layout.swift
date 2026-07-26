//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import FactoryKit
import JellyfinAPI
import SwiftUI

extension TabItem {

    static var defaultItems: [TabItem] {
        [.home, .search, .media]
    }

    @MainActor
    static func layoutItems(
        configuration: LayoutConfiguration,
        advanced: Bool,
        experimentEnabled: Bool
    ) -> [TabItem] {
        guard advanced && experimentEnabled else { return defaultItems }

        var items = configuration.tabs.compactMap { TabItem($0, in: configuration) }.uniqued { $0.id }
        items = Array(items.prefix(LayoutConfiguration.maximumTabCount))
        guard items.isNotEmpty else { return defaultItems }

        return items
    }

    @MainActor
    init?(_ tab: TabConfiguration, in layout: LayoutConfiguration) {
        let view: ContentViewConfiguration?
        if case let .contentView(id) = tab.destination {
            guard let configuration = layout.view(withID: id) else { return nil }

            view = configuration
        } else {
            view = nil
        }

        if case .admin = tab.destination {
            guard Container.shared.currentUserSession()?.userData.policy?.isAdministrator == true else { return nil }
        }

        if case let .item(item) = tab.destination, item.id.nilIfBlank == nil {
            return nil
        }

        self.init(
            id: tab.id,
            title: layout.title(for: tab),
            systemImage: layout.icon(for: tab),
            destination: tab.destination
        ) {
            Self.content(for: tab, view: view)
        }
    }

    @ContentBuilder
    private static func content(for tab: TabConfiguration, view: ContentViewConfiguration?) -> some View {
        switch tab.destination {
        case .home:
            ContentGroupView(provider: DefaultContentGroupProvider())

        case .search:
            SearchView()

        case .media:
            PagingLibraryView(library: UserViewLibrary())

        case .liveTV:
            NavigationRoute.liveTV.destination

        case let .item(item):
            switch item.itemType {
            case .collectionFolder, .folder, .userView:
                PagingLibraryView(library: ItemLibrary(parent: item.baseItem, filters: .default))
            default:
                NavigationRoute.item(item: item.baseItem).destination
            }

        case .contentView:
            if let view {
                ContentGroupView(provider: ContentViewGroupProvider(configuration: view))
                    .id(view)
            }

        case let .admin(destination):
            switch destination {
            case .dashboard: AdminDashboardView()
            case .activity: ServerActivityView()
            case .sessions: ActiveSessionsView()
            }
        }
    }
}

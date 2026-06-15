//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@MainActor
final class TabCoordinator: ObservableObject {

    struct SelectedEvent {
        let isRoot: Bool
        let isRepeat: Bool
    }

    typealias TabData = (
        item: TabItem,
        coordinator: NavigationCoordinator,
        publisher: TabItemSelectedPublisher
    )

    @Published
    var selectedTabID: String! = nil {
        didSet {
            guard let tab = tabs.first(property: \.item.id, equalTo: selectedTabID) else { return }

            tab.publisher.send(
                .init(
                    isRoot: tab.coordinator.path.isEmpty,
                    isRepeat: oldValue == selectedTabID
                )
            )
        }
    }

    @Published
    var tabs: [TabData] = []

    init(@ArrayBuilder<TabItem> tabs: () -> [TabItem]) {
        let tabs = tabs()
        setTabs(tabs)
        self.selectedTabID = tabs.first?.id
    }

    init(@ArrayBuilder<TabItemSetting> tabs: () -> [TabItemSetting]) {
        let tabs = tabs()
        setTabs(tabs.map(\.item))
        self.selectedTabID = tabs.first?.item.id
    }

    init(tabs: [TabItemSetting]) {
        setTabs(tabs.map(\.item))
        self.selectedTabID = self.tabs.first?.item.id
    }

    func setTabs(_ tabItems: [TabItem]) {
        let previousTabsByID = Dictionary(uniqueKeysWithValues: tabs.map { ($0.item.id, $0) })

        self.tabs = tabItems.map { tab in
            if let previous = previousTabsByID[tab.id] {
                return (tab, previous.coordinator, previous.publisher)
            }

            return (tab, NavigationCoordinator(), TabItemSelectedPublisher())
        }

        if !tabItems.contains(where: { $0.id == selectedTabID }) {
            selectedTabID = tabItems.first?.id
        }
    }

    func setTabs(_ tabSettings: [TabItemSetting]) {
        setTabs(tabSettings.map(\.item))
    }

    func route(to route: NavigationRoute) async {
        guard let tab = tabs.first(where: { $0.item.id == selectedTabID }) else { return }
        tab.coordinator.push(route)
    }
}

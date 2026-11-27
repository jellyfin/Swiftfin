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
    private(set) var tabs: [TabData]

    init(@ArrayBuilder<TabItem> tabs: () -> [TabItem]) {
        let tabs = tabs()
        self.tabs = tabs.map { tab in
            (tab, NavigationCoordinator(), TabItemSelectedPublisher())
        }
        self.selectedTabID = tabs.first?.id
    }

    #if os(iOS)
    init(tabs: [TabItem]) {
        self.tabs = []
        updateTabs(tabs)
    }

    func updateTabs(_ items: [TabItem]) {
        var existingTabs: [TabItem.ID: TabData] = [:]
        tabs.forEach { existingTabs[$0.item.id] = $0 }

        tabs = items.uniqued { $0.id }.map { item in
            if let existingTab = existingTabs[item.id],
               existingTab.item.destination == item.destination {
                return (
                    item,
                    existingTab.coordinator,
                    existingTab.publisher
                )
            }

            return (
                item,
                NavigationCoordinator(),
                TabItemSelectedPublisher()
            )
        }

        if tabs.contains(where: { $0.item.id == selectedTabID }) {
            return
        }

        selectedTabID = tabs.first?.item.id
    }

    #endif

    func route(to route: NavigationRoute) async {
        guard let tab = tabs.first(where: { $0.item.id == selectedTabID }) else { return }

        tab.coordinator.push(route)
    }
}

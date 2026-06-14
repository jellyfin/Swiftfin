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
        self.tabs = tabs.map { tab in
            let coordinator = NavigationCoordinator()
            let event = TabItemSelectedPublisher()
            return (tab, coordinator, event)
        }
    }

    func route(to route: NavigationRoute, in tabID: String = "home") {
        guard let tab = tabs.first(where: { $0.item.id == tabID }) ?? tabs.first else { return }

        selectedTabID = tab.item.id
        tab.coordinator.path = []
        tab.coordinator.presentedSheet = nil
        tab.coordinator.presentedFullScreen = nil
        tab.coordinator.push(route)
    }
}

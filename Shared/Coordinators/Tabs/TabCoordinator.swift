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

            let isRepeat = oldValue == selectedTabID

            tab.publisher.send(
                .init(
                    isRoot: tab.coordinator.path.isEmpty,
                    isRepeat: isRepeat
                )
            )

            // Pressing Select on the ALREADY-ACTIVE Home tab (a re-select, not a switch from another
            // tab) collapses the Home stack back to its root — like a long-press of Back. Scoped to a
            // re-select so switching in from another tab keeps Home where it was.
            if isRepeat, tab.item.id == "home" {
                tab.coordinator.dismissToRoot()
            }
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

        tab.coordinator.presentedSheet = nil
        tab.coordinator.presentedFullScreen = nil
        // Only change tab selection when actually switching tabs. Re-selecting the already-active Home tab
        // fires a `didSet` that collapses the stack to root (a flash of Home); skipping it lets us replace
        // the stack in one shot below.
        if selectedTabID != tab.item.id {
            selectedTabID = tab.item.id
        }
        // Push the target item ON TOP of whatever's there (count grows → a normal push that renders
        // immediately) so we go STRAIGHT to the item with no intermediate Home flash. (Replacing the
        // single top element in place does NOT re-render the tvOS NavigationStack.)
        tab.coordinator.path.append(route)
    }
}

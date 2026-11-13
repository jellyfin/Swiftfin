//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Foundation

struct LayoutConfiguration: Hashable, Storable {

    var tabs: [TabConfiguration]
    var views: [ContentViewConfiguration]

    init(tabs: [TabConfiguration] = Self.defaultTabs, views: [ContentViewConfiguration] = []) {
        self.tabs = tabs
        self.views = views
    }

    static let maximumTabCount = 5

    var canAddTab: Bool {
        tabs.count < Self.maximumTabCount
    }

    func title(for tab: TabConfiguration) -> String {
        if case let .contentView(id) = tab.destination {
            return view(withID: id)?.displayTitle ?? tab.destination.displayTitle
        }
        return tab.destination.displayTitle
    }

    func icon(for tab: TabConfiguration) -> String {
        if case let .contentView(id) = tab.destination {
            return view(withID: id)?.systemImage ?? tab.destination.systemImage
        }
        return tab.destination.systemImage
    }

    func canAddTab(destination: TabDestination) -> Bool {
        guard canAddTab else { return false }

        switch destination {
        case let .item(item):
            guard item.id.nilIfBlank != nil else { return false }

            return !tabs.contains {
                guard case let .item(existingItem) = $0.destination else { return false }

                return existingItem.id == item.id
            }

        case let .contentView(id) where view(withID: id) == nil:
            return false

        default:
            return !tabs.contains { $0.destination == destination }
        }
    }

    @discardableResult
    mutating func addTab(destination: TabDestination) -> Bool {
        guard canAddTab(destination: destination) else { return false }

        tabs.append(TabConfiguration(destination: destination))
        return true
    }

    @discardableResult
    mutating func saveView(_ view: ContentViewConfiguration) -> Bool {
        guard view.hasValidName else { return false }

        var view = view
        view.name = view.name.trimmingCharacters(in: .whitespacesAndNewlines)
        if let index = views.firstIndex(where: { $0.id == view.id }) {
            views[index] = view
        } else {
            views.append(view)
        }
        return true
    }

    mutating func removeView(id: ContentViewConfiguration.ID) {
        views.removeAll { $0.id == id }
        tabs.removeAll { $0.destination == .contentView(id: id) }
        if tabs.isEmpty {
            tabs = Self.defaultTabs
        }
    }

    static let `default` = Self()
    static var defaultTabs: [TabConfiguration] {
        [.home, .search, .media]
    }

    func view(withID id: String) -> ContentViewConfiguration? {
        views.first { $0.id == id }
    }
}

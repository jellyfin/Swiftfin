//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: selected icon
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

    static let home = TabItem(
        id: "home",
        title: L10n.home,
        systemImage: "house"
    ) {
        HomeView()
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
            let viewModel = ItemLibraryViewModel(
                filters: filters
            )

            PagingLibraryView(viewModel: viewModel)
        }
    }

    static let media = TabItem(
        id: "media",
        title: L10n.media,
        systemImage: "rectangle.stack.fill"
    ) {
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

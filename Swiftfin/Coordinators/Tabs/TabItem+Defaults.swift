//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension TabItem {

    static var media: TabItem {
        TabItem(
            id: "media",
            title: L10n.media,
            systemImage: "rectangle.stack.fill",
            destination: .media
        ) {
            PagingLibraryView(library: UserViewLibrary())
        }
    }

    static var home: TabItem {
        TabItem(
            id: DefaultContentGroupProvider().id,
            title: L10n.home,
            systemImage: "house.fill",
            destination: .home
        ) {
            ContentGroupView(provider: DefaultContentGroupProvider())
        }
    }

    static var search: TabItem {
        TabItem(
            id: "search",
            title: L10n.search,
            systemImage: "magnifyingglass",
            destination: .search
        ) {
            SearchView()
        }
    }
}

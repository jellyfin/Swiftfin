//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct HomePosterSettingsView: View {

    @StoredValue
    private var libraryStyle: LibraryStyle

    private let group: HomePosterGroup

    init(group: HomePosterGroup) {
        self.group = group
        _libraryStyle = StoredValue(group.libraryStyleKey)
    }

    @ContentBuilder
    var body: some View {
        Form(systemImage: "rectangle.3.group") {
            PosterGroupSettingsEditor(
                displayType: $libraryStyle.posterDisplayType,
                size: $libraryStyle.posterSize.coalesce(group.defaultSettings.size.posterSize)
            )
        }
        .navigationTitle(group.displayTitle)
    }
}

extension HomePosterSettingsView {

    struct Row: View {

        @Router
        private var router

        @StoredValue
        private var libraryStyle: LibraryStyle

        let group: HomePosterGroup

        init(group: HomePosterGroup) {
            self.group = group
            _libraryStyle = StoredValue(group.libraryStyleKey)
        }

        @ContentBuilder
        var body: some View {
            ChevronButton(group.displayTitle) {
                router.route(to: NavigationRoute(id: "home-posters-\(group.rawValue)") {
                    HomePosterSettingsView(group: group)
                })
            } content: {
                Text(libraryStyle.posterDisplayType.displayTitle)
            }
        }
    }
}

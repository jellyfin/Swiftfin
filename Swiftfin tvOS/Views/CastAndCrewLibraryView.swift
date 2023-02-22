//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CollectionView
import JellyfinAPI
import SwiftUI

struct CastAndCrewLibraryView: View {

    @EnvironmentObject
    private var router: CastAndCrewLibraryCoordinator.Router

    let people: [BaseItemPerson]

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }

    @ViewBuilder
    private var libraryGridView: some View {
        CollectionView(items: people) { _, person, _ in
            PosterButton(item: person, type: .portrait)
                .onSelect {
                    router.route(to: \.library, .init(parent: person, type: .person, filters: .init()))
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: .fixedNumberOfColumns(7),
                lineSpacing: 50
            )
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
    }

    var body: some View {
        Group {
            if people.isEmpty {
                noResultsView
            } else {
                libraryGridView
            }
        }
        .ignoresSafeArea()
    }
}

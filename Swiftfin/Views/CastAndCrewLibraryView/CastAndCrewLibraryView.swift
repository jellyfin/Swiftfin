//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct CastAndCrewLibraryView: View {

    @Default(.Customization.Library.viewType)
    private var libraryViewType

    @EnvironmentObject
    private var router: CastAndCrewLibraryCoordinator.Router

    let people: [BaseItemPerson]

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }

    @ViewBuilder
    private var libraryListView: some View {
        CollectionView(items: people) { _, person, _ in
            CastAndCrewItemRow(person: person)
                .onSelect {
                    router.route(to: \.library, .init(parent: person, type: .person, filters: .init()))
                }
                .padding()
        }
        .layout { _, layoutEnvironment in
            .list(using: .init(appearance: .plain), layoutEnvironment: layoutEnvironment)
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
    }

    @ViewBuilder
    private var libraryGridView: some View {
        CollectionView(items: people) { _, person, _ in
            PosterButton(state: .item(person), type: .portrait)
                .onSelect {
                    router.route(to: \.library, .init(parent: person, type: .person, filters: .init()))
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: .adaptive(withMinItemSize: PosterType.portrait.width + (UIDevice.isIPad ? 10 : 0)),
                sectionInsets: .init(top: 0, leading: 10, bottom: 0, trailing: 10)
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
                switch libraryViewType {
                case .grid:
                    libraryGridView
                case .list:
                    libraryListView
                }
            }
        }
        .navigationTitle(L10n.castAndCrew)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                LibraryViewTypeToggle(libraryViewType: $libraryViewType)
            }
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: This only exists because of the restriction on poster types,
//       should find a way to consolidate into `PagingLibraryView`?
struct CastAndCrewLibraryView: View {

    @Default(.Customization.Library.listColumnCount)
    private var listColumnCount
    @Default(.Customization.Library.viewType)
    private var libraryViewType

    @EnvironmentObject
    private var router: CastAndCrewLibraryCoordinator.Router

    @State
    private var layout: CollectionVGridLayout = .columns(3)

    let people: [BaseItemPerson]

    private func padLayout(libraryViewType: LibraryViewType) -> CollectionVGridLayout {
        switch libraryViewType {
        case .landscapeGrid, .portraitGrid:
            .minWidth(150)
        case .list:
            .columns(listColumnCount, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    private func phoneLayout(libraryViewType: LibraryViewType) -> CollectionVGridLayout {
        switch libraryViewType {
        case .landscapeGrid, .portraitGrid:
            .columns(3)
        case .list:
            .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }
    
    private func gridItemView(person: BaseItemPerson) -> some View {
        PosterButton(item: person, type: .portrait)
            .onSelect {
                router.route(to: \.library, .init(parent: person, type: .person, filters: .init()))
            }
    }
    
    private func listItemView(person: BaseItemPerson) -> some View {
        LibraryItemRow(item: person)
            .onSelect {
                router.route(to: \.library, .init(parent: person, type: .person, filters: .init()))
            }
            .padding(10)
            .overlay(alignment: .bottom) {
                Divider()
            }
    }

    @ViewBuilder
    private var libraryView: some View {
        CollectionVGrid(
            people,
            layout: $layout
        ) { person in
            switch libraryViewType {
            case .landscapeGrid, .portraitGrid:
                gridItemView(person: person)
            case .list:
                listItemView(person: person)
            }
        }
    }

    var body: some View {
        Group {
            if people.isEmpty {
                noResultsView
            } else {
                libraryView
            }
        }
        .onAppear {
            if UIDevice.isPhone {
                layout = phoneLayout(libraryViewType: libraryViewType)
            } else {
                layout = padLayout(libraryViewType: libraryViewType)
            }
        }
        .onChange(of: libraryViewType) { _ in
            if UIDevice.isPhone {
                layout = phoneLayout(libraryViewType: libraryViewType)
            } else {
                layout = padLayout(libraryViewType: libraryViewType)
            }
        }
        .navigationTitle(L10n.castAndCrew)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                LibraryViewTypeToggle(
                    libraryViewType: $libraryViewType,
                    allowedTypes: [
                        .portraitGrid,
                        .list,
                    ]
                )
            }
        }
    }
}

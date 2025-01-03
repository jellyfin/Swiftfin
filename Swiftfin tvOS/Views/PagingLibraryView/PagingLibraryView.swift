//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: Figure out proper tab bar handling with the collection offset
// TODO: list columns
// TODO: list row view (LibraryRow)
// TODO: fix paging for next item focusing the tab

struct PagingLibraryView<Element: Poster & Identifiable>: View {

    @Default(.Customization.Library.cinematicBackground)
    private var cinematicBackground
    @Default(.Customization.Library.posterType)
    private var posterType
    @Default(.Customization.Library.displayType)
    private var viewType
    @Default(.Customization.showPosterLabels)
    private var showPosterLabels

    @EnvironmentObject
    private var router: LibraryCoordinator<Element>.Router

    @State
    private var focusedItem: Element?

    @State
    private var presentBackground = false
    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var viewModel: PagingLibraryViewModel<Element>

    @StateObject
    private var cinematicBackgroundViewModel: CinematicBackgroundView<Element>.ViewModel = .init()

    init(viewModel: PagingLibraryViewModel<Element>) {
        self._viewModel = StateObject(wrappedValue: viewModel)

        let initialPosterType = Defaults[.Customization.Library.posterType]
        let initialViewType = Defaults[.Customization.Library.displayType]
        let listColumnCount = Defaults[.Customization.Library.listColumnCount]

        self._layout = State(
            initialValue: Self.makeLayout(
                posterType: initialPosterType,
                displayType: initialViewType,
                listColumnCount: listColumnCount
            )
        )
    }

    // MARK: onSelect

    private func onSelect(_ element: Element) {
        switch element {
        case let element as BaseItemDto:
            select(item: element)
        case let element as BaseItemPerson:
            select(person: element)
        default:
            assertionFailure("Used an unexpected type within a `PagingLibaryView`?")
        }
    }

    private func select(item: BaseItemDto) {
        switch item.type {
        case .collectionFolder, .folder:
            let viewModel = ItemLibraryViewModel(parent: item)
            router.route(to: \.library, viewModel)
        default:
            router.route(to: \.item, item)
        }
    }

    private func select(person: BaseItemPerson) {
        let viewModel = ItemLibraryViewModel(parent: person)
        router.route(to: \.library, viewModel)
    }

    // MARK: layout

    private static func makeLayout(
        posterType: PosterDisplayType,
        displayType: LibraryDisplayType,
        listColumnCount: Int
    ) -> CollectionVGridLayout {
        switch (posterType, displayType) {
        case (.landscape, .grid):
            return .columns(5, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        case (.portrait, .grid):
            return .columns(7, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        case (_, .list):
            return .columns(listColumnCount, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        }
    }

    private func landscapeGridItemView(item: Element) -> some View {
        PosterButton(item: item, type: .landscape)
            .content {
                if item.showTitle {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                }
            }
            .onFocusChanged { newValue in
                if newValue {
                    focusedItem = item
                }
            }
            .onSelect {
                onSelect(item)
            }
    }

    private func portraitGridItemView(item: Element) -> some View {
        PosterButton(item: item, type: .portrait)
            .content {
                if item.showTitle {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                }
            }
            .onFocusChanged { newValue in
                if newValue {
                    focusedItem = item
                }
            }
            .onSelect {
                onSelect(item)
            }
    }

    @ViewBuilder
    private func listItemView(item: Element, posterType: PosterDisplayType) -> some View {
        LibraryRow(item: item, posterType: posterType)
            .onFocusChanged { newValue in
                if newValue {
                    focusedItem = item
                }
            }
            .onSelect {
                onSelect(item)
            }
    }

    @ViewBuilder
    private var contentView: some View {
        CollectionVGrid(
            uniqueElements: viewModel.elements,
            layout: layout
        ) { item in
            switch (posterType, viewType) {
            case (.landscape, .grid):
                landscapeGridItemView(item: item)
            case (.portrait, .grid):
                portraitGridItemView(item: item)
            case (_, .list):
                listItemView(item: item, posterType: posterType)
            }
        }
        .onReachedBottomEdge(offset: .rows(3)) {
            viewModel.send(.getNextPage)
        }
    }

    var body: some View {
        ZStack {
            if cinematicBackground {
                CinematicBackgroundView(viewModel: cinematicBackgroundViewModel)
                    .visible(presentBackground)
                    .blurred()
            }

            WrappedView {
                Group {
                    switch viewModel.state {
                    case let .error(error):
                        Text(error.localizedDescription)
                    case .initial, .refreshing:
                        ProgressView()
                    case .content:
                        if viewModel.elements.isEmpty {
                            L10n.noResults.text
                        } else {
                            contentView
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
        .navigationTitle(viewModel.parent?.displayTitle ?? "")
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.send(.refresh)
            }
        }
        .onChange(of: focusedItem) { _, newValue in
            guard let newValue else {
                withAnimation {
                    presentBackground = false
                }
                return
            }

            cinematicBackgroundViewModel.select(item: newValue)

            if !presentBackground {
                withAnimation {
                    presentBackground = true
                }
            }
        }
    }
}

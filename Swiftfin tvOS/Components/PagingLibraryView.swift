//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: Figure out proper tab bar handling with the collection offset
// TODO: list columns
// TODO: list row view (LibraryRow)

struct PagingLibraryView<Element: Poster>: View {

    @Default(.Customization.Library.cinematicBackground)
    private var cinematicBackground
    @Default(.Customization.Library.posterType)
    private var posterType
    @Default(.Customization.Library.viewType)
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
        let initialViewType = Defaults[.Customization.Library.viewType]

        self._layout = State(
            initialValue: Self.makeLayout(
                posterType: initialPosterType,
                viewType: initialViewType
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
        posterType: PosterType,
        viewType: LibraryViewType
    ) -> CollectionVGridLayout {
        switch (posterType, viewType) {
        case (.landscape, .grid):
            .columns(5)
        case (.portrait, .grid):
            .columns(7, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        case (_, .list):
            .columns(1)
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

    private func listItemView(item: Element) -> some View {
        Button(item.displayTitle)
    }

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.elements,
            layout: layout
        ) { item in
            switch (posterType, viewType) {
            case (.landscape, .grid):
                landscapeGridItemView(item: item)
            case (.portrait, .grid):
                portraitGridItemView(item: item)
            case (_, .list):
                listItemView(item: item)
            }
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
                    case .gettingNextPage, .content:
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
        .onChange(of: focusedItem) { newValue in
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

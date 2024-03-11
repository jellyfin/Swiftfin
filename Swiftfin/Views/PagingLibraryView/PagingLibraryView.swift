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

// Note: Currently, it is a conscious decision to not have grid posters have subtitle content.
//       This is due to episodes, which have their `S_E_` subtitles, and these can be alongside
//       other items that don't have a subtitle which requires the entire library to implement
//       subtitle content but that doesn't look appealing. Until a solution arrives grid posters
//       will not have subtitle content.

struct PagingLibraryView<Element: Poster>: View {

    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters
    @Default(.Customization.Library.listColumnCount)
    private var listColumnCount
    @Default(.Customization.Library.posterType)
    private var posterType
    @Default(.Customization.Library.viewType)
    private var viewType

    @EnvironmentObject
    private var router: LibraryCoordinator<Element>.Router

    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var collectionVGridProxy: CollectionVGridProxy<Element> = .init()
    @StateObject
    private var viewModel: PagingLibraryViewModel<Element>

    // MARK: init

    init(viewModel: PagingLibraryViewModel<Element>) {
        self._viewModel = StateObject(wrappedValue: viewModel)

        let initialPosterType = Defaults[.Customization.Library.posterType]
        let initialViewType = Defaults[.Customization.Library.viewType]
        let initialListColumnCount = Defaults[.Customization.Library.listColumnCount]

        if UIDevice.isPhone {
            layout = Self.phoneLayout(
                posterType: initialPosterType,
                viewType: initialViewType
            )
        } else {
            layout = Self.padLayout(
                posterType: initialPosterType,
                viewType: initialViewType,
                listColumnCount: initialListColumnCount
            )
        }
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
            let viewModel = ItemLibraryViewModel(parent: item, filters: .default)
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

    private static func padLayout(
        posterType: PosterType,
        viewType: LibraryViewType,
        listColumnCount: Int
    ) -> CollectionVGridLayout {
        switch (posterType, viewType) {
        case (.landscape, .grid):
            .minWidth(200)
        case (.portrait, .grid):
            .minWidth(150)
        case (_, .list):
            .columns(listColumnCount, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    private static func phoneLayout(
        posterType: PosterType,
        viewType: LibraryViewType
    ) -> CollectionVGridLayout {
        switch (posterType, viewType) {
        case (.landscape, .grid):
            .columns(2)
        case (.portrait, .grid):
            .columns(3)
        case (_, .list):
            .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        }
    }

    // MARK: item view

    private func landscapeGridItemView(item: Element) -> some View {
        PosterButton(item: item, type: .landscape)
            .content {
                if item.showTitle {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
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
            .onSelect {
                onSelect(item)
            }
    }

    private func listItemView(item: Element) -> some View {
        LibraryRow(item: item, posterType: posterType)
            .onSelect {
                onSelect(item)
            }
    }

    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
            }
    }

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.elements,
            layout: $layout
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
        .onReachedBottomEdge(offset: 300) {
            viewModel.send(.getNextPage)
        }
        .proxy(collectionVGridProxy)
    }

    // MARK: body

    var body: some View {
        WrappedView {
            Group {
                switch viewModel.state {
                case let .error(error):
                    errorView(with: error)
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
            .transition(.opacity.animation(.linear(duration: 0.2)))
        }
        .ignoresSafeArea()
        .navigationTitle(viewModel.parent?.displayTitle ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .ifLet(viewModel.filterViewModel) { view, filterViewModel in
            view.navigationBarFilterDrawer(
                viewModel: filterViewModel,
                types: enabledDrawerFilters
            ) {
                router.route(to: \.filter, $0)
            }
        }
        .onChange(of: posterType) { newValue in
            if UIDevice.isPhone {
                if viewType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.phoneLayout(
                        posterType: newValue,
                        viewType: viewType
                    )
                }
            } else {
                if viewType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.padLayout(
                        posterType: newValue,
                        viewType: viewType,
                        listColumnCount: listColumnCount
                    )
                }
            }
        }
        .onChange(of: viewType) { newValue in
            if UIDevice.isPhone {
                layout = Self.phoneLayout(
                    posterType: posterType,
                    viewType: newValue
                )
            } else {
                layout = Self.padLayout(
                    posterType: posterType,
                    viewType: newValue,
                    listColumnCount: listColumnCount
                )
            }
        }
        .onChange(of: listColumnCount) { newValue in
            if UIDevice.isPad {
                layout = Self.padLayout(
                    posterType: posterType,
                    viewType: viewType,
                    listColumnCount: newValue
                )
            }
        }
        .onReceive(viewModel.events) { event in
            switch event {
            case let .gotRandomItem(item):
                switch item {
                case let item as BaseItemDto:
                    router.route(to: \.item, item)
                case let item as BaseItemPerson:
                    let viewModel = ItemLibraryViewModel(parent: item, filters: .default)
                    router.route(to: \.library, viewModel)
                default:
                    assertionFailure("Used an unexpected type within a `PagingLibaryView`?")
                }
            }
        }
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.send(.refresh)
            }
        }
        .topBarTrailing {

            if viewModel.state == .gettingNextPage {
                ProgressView()
            }

            Menu {

                LibraryViewTypeToggle(posterType: $posterType, viewType: $viewType, listColumnCount: $listColumnCount)

                Button(L10n.random, systemImage: "dice.fill") {
                    viewModel.send(.getRandomItem)
                }
                .disabled(viewModel.elements.isEmpty)
            } label: {
                Image(systemName: "ellipsis.circle")
            }
        }
    }
}

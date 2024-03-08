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

struct PagingLibraryView<Element: Poster>: View {

    @Default(.Customization.Library.cinematicBackground)
    private var cinematicBackground
    @Default(.Customization.Library.viewType)
    private var libraryViewType
    @Default(.Customization.showPosterLabels)
    private var showPosterLabels

    @EnvironmentObject
    private var router: LibraryCoordinator<Element>.Router

    @FocusState
    private var focusedItem: BaseItemDto?

    @State
    private var presentBackground = false
    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var viewModel: PagingLibraryViewModel<Element>

    @StateObject
    private var cinematicBackgroundViewModel: CinematicBackgroundView<BaseItemDto>.ViewModel = .init()

    init(viewModel: PagingLibraryViewModel<Element>) {
        self._viewModel = StateObject(wrappedValue: viewModel)

        let initialLibraryViewType = Defaults[.Customization.Library.viewType]

        self._layout = State(initialValue: Self.makeLayout(libraryViewType: initialLibraryViewType))
    }

    // MARK: onSelect

    private func onSelect(_ element: Element) {
        switch element {
        case let element as BaseItemDto:
            select(item: element)
        case let element as BaseItemPerson:
            select(person: element)
        default:
            fatalError("Used an unexpected type within a `PagingLibaryView`?")
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

    private static func makeLayout(libraryViewType: LibraryViewType) -> CollectionVGridLayout {
        switch libraryViewType {
        case .landscapeGrid:
            .columns(5)
        case .portraitGrid:
            .columns(7)
        case .list:
            .columns(1)
        }
    }

    private func landscapeGridItemView(item: Element) -> some View {
        PosterButton(item: item, type: .landscape)
//            .content {
//                if item.showTitle {
//                    PosterButton.TitleContentView(item: item)
//                        .backport
//                        .lineLimit(1, reservesSpace: true)
//                }
//            }
                .onSelect {
                    onSelect(item)
                }
    }

    private func portraitGridItemView(item: Element) -> some View {
        PosterButton(item: item, type: .portrait)
//            .content {
//                if item.showTitle {
//                    PosterButton.TitleContentView(item: item)
//                        .backport
//                        .lineLimit(1, reservesSpace: true)
//                }
//            }
                .onSelect {
                    onSelect(item)
                }
    }

    private func listItemView(item: Element) -> some View {
        Button(item.displayTitle)
//        LibraryRow(item: item)
//            .onSelect {
//                onSelect(item)
//            }
    }

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.items,
            layout: layout
        ) { item in
            switch libraryViewType {
            case .landscapeGrid:
                landscapeGridItemView(item: item)
            case .portraitGrid:
                portraitGridItemView(item: item)
            case .list:
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
                    case .refreshing:
                        ProgressView()
                    case .gettingNextPage, .content:
                        if viewModel.items.isEmpty {
                            L10n.noResults.text
                        } else {
                            contentView
                        }
                    }
                }
            }
        }
        .ignoresSafeArea(edges: .bottom)
        .ignoresSafeArea(edges: .horizontal)
        .onFirstAppear {
            // May have been passed a view model that already had a page of items
            if viewModel.items.isEmpty {
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

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
// TODO: fix paging for next item focusing the tab

struct PagingLibraryView<Element: Poster & Identifiable>: View {

    @Default(.Customization.Library.cinematicBackground)
    private var cinematicBackground
    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters
    @Default(.Customization.Library.rememberLayout)
    private var rememberLayout

    @Default
    private var defaultDisplayType: LibraryDisplayType
    @Default
    private var defaultListColumnCount: Int
    @Default
    private var defaultPosterType: PosterDisplayType

    @EnvironmentObject
    private var router: LibraryCoordinator<Element>.Router

    @State
    private var focusedItem: Element?
    @State
    private var presentBackground = false
    @State
    private var layout: CollectionVGridLayout
    @State
    private var safeArea: EdgeInsets = .zero

    @StoredValue
    private var displayType: LibraryDisplayType
    @StoredValue
    private var listColumnCount: Int
    @StoredValue
    private var posterType: PosterDisplayType

    @StateObject
    private var collectionVGridProxy: CollectionVGridProxy = .init()
    @StateObject
    private var viewModel: PagingLibraryViewModel<Element>

    @StateObject
    private var cinematicBackgroundViewModel: CinematicBackgroundView<Element>.ViewModel = .init()

    init(viewModel: PagingLibraryViewModel<Element>) {

        self._defaultDisplayType = Default(.Customization.Library.displayType)
        self._defaultListColumnCount = Default(.Customization.Library.listColumnCount)
        self._defaultPosterType = Default(.Customization.Library.posterType)

        self._displayType = StoredValue(.User.libraryDisplayType(parentID: viewModel.parent?.id))
        self._listColumnCount = StoredValue(.User.libraryListColumnCount(parentID: viewModel.parent?.id))
        self._posterType = StoredValue(.User.libraryPosterType(parentID: viewModel.parent?.id))

        self._viewModel = StateObject(wrappedValue: viewModel)

        let initialDisplayType = Defaults[.Customization.Library.rememberLayout] ? _displayType.wrappedValue : _defaultDisplayType
            .wrappedValue
        let initialListColumnCount = Defaults[.Customization.Library.rememberLayout] ? _listColumnCount
            .wrappedValue : _defaultListColumnCount.wrappedValue
        let initialPosterType = Defaults[.Customization.Library.rememberLayout] ? _posterType.wrappedValue : _defaultPosterType.wrappedValue

        self._layout = State(
            initialValue: Self.makeLayout(
                posterType: initialPosterType,
                viewType: initialDisplayType,
                listColumnCount: initialListColumnCount
            )
        )
    }

    // MARK: On Select

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

    // MARK: Select Item

    private func select(item: BaseItemDto) {
        switch item.type {
        case .collectionFolder, .folder:
            let viewModel = ItemLibraryViewModel(parent: item, filters: .default)
            router.route(to: \.library, viewModel)
        case .person:
            let viewModel = ItemLibraryViewModel(parent: item)
            router.route(to: \.library, viewModel)
        default:
            router.route(to: \.item, item)
        }
    }

    // MARK: Select Person

    private func select(person: BaseItemPerson) {
        let viewModel = ItemLibraryViewModel(parent: person)
        router.route(to: \.library, viewModel)
    }

    // MARK: Make Layout

    private static func makeLayout(
        posterType: PosterDisplayType,
        viewType: LibraryDisplayType,
        listColumnCount: Int
    ) -> CollectionVGridLayout {
        switch (posterType, viewType) {
        case (.landscape, .grid):
            return .columns(5, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        case (.portrait, .grid):
            return .columns(7, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        case (_, .list):
            return .columns(listColumnCount, insets: .init(50), itemSpacing: 50, lineSpacing: 50)
        }
    }

    // MARK: Set Default Layout

    private func setDefaultLayout() {
        layout = Self.makeLayout(
            posterType: defaultPosterType,
            viewType: defaultDisplayType,
            listColumnCount: defaultListColumnCount
        )
    }

    // MARK: Set Custom Layout

    private func setCustomLayout() {
        layout = Self.makeLayout(
            posterType: posterType,
            viewType: displayType,
            listColumnCount: listColumnCount
        )
    }

    // MARK: Set Cinematic Background

    private func setCinematicBackground() {
        guard let focusedItem else {
            withAnimation {
                presentBackground = false
            }
            return
        }

        cinematicBackgroundViewModel.select(item: focusedItem)

        if !presentBackground {
            withAnimation {
                presentBackground = true
            }
        }
    }

    // MARK: Landscape Grid Item View

    private func landscapeGridItemView(item: Element) -> some View {
        PosterButton(item: item, type: .landscape)
            .content {
                if item.showTitle {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                } else if viewModel.parent?.libraryType == .folder {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                        .hidden()
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

    // MARK: Portrait Grid Item View

    @ViewBuilder
    private func portraitGridItemView(item: Element) -> some View {
        PosterButton(item: item, type: .portrait)
            .content {
                if item.showTitle {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                } else if viewModel.parent?.libraryType == .folder {
                    PosterButton.TitleContentView(item: item)
                        .backport
                        .lineLimit(1, reservesSpace: true)
                        .hidden()
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

    // MARK: List Item View

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

    // MARK: Error View

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
            }
    }

    // MARK: Grid View

    @ViewBuilder
    private var gridView: some View {
        CollectionVGrid(
            uniqueElements: viewModel.elements,
            layout: layout
        ) { item in

            let displayType = Defaults[.Customization.Library.rememberLayout] ? _displayType.wrappedValue : _defaultDisplayType
                .wrappedValue
            let posterType = Defaults[.Customization.Library.rememberLayout] ? _posterType.wrappedValue : _defaultPosterType.wrappedValue

            switch (posterType, displayType) {
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
        .proxy(collectionVGridProxy)
        .scrollIndicatorsVisible(false)
    }

    // MARK: Inner Content View

    @ViewBuilder
    private var innerContent: some View {
        switch viewModel.state {
        case .content:
            if viewModel.elements.isEmpty {
                L10n.noResults.text
            } else {
                gridView
            }
        case .initial, .refreshing:
            ProgressView()
        default:
            AssertionFailureView("Expected view for unexpected state")
        }
    }

    // MARK: Content View

    @ViewBuilder
    private var contentView: some View {

        innerContent
            // These exist here to alleviate type-checker issues
                .onChange(of: posterType) {
                    setCustomLayout()
                }
                .onChange(of: displayType) {
                    setCustomLayout()
                }
                .onChange(of: listColumnCount) {
                    setCustomLayout()
                }

        // Logic for LetterPicker. Enable when ready

        /* if letterPickerEnabled, let filterViewModel = viewModel.filterViewModel {
             ZStack(alignment: letterPickerOrientation.alignment) {
                 innerContent
                     .padding(letterPickerOrientation.edge, LetterPickerBar.size + 10)
                     .frame(maxWidth: .infinity)

                 LetterPickerBar(viewModel: filterViewModel)
                     .padding(.top, safeArea.top)
                     .padding(.bottom, safeArea.bottom)
                     .padding(letterPickerOrientation.edge, 10)
             }
         } else {
            innerContent
         }
         // These exist here to alleviate type-checker issues
         .onChange(of: posterType) {
             setCustomLayout()
         }
         .onChange(of: displayType) {
             setCustomLayout()
         }
         .onChange(of: listColumnCount) {
             setCustomLayout()
         }*/
    }

    // MARK: Body

    var body: some View {
        ZStack {
            Color.clear

            if cinematicBackground {
                CinematicBackgroundView(viewModel: cinematicBackgroundViewModel)
                    .visible(presentBackground)
                    .blurred()
            }

            switch viewModel.state {
            case .content, .initial, .refreshing:
                contentView
            case let .error(error):
                errorView(with: error)
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea()
        .navigationTitle(viewModel.parent?.displayTitle ?? "")
        .onChange(of: focusedItem) {
            setCinematicBackground()
        }
        .onChange(of: rememberLayout) {
            if rememberLayout {
                setCustomLayout()
            } else {
                setDefaultLayout()
            }
        }
        .onChange(of: defaultPosterType) {
            guard !Defaults[.Customization.Library.rememberLayout] else { return }
            setDefaultLayout()
        }
        .onChange(of: defaultDisplayType) {
            guard !Defaults[.Customization.Library.rememberLayout] else { return }
            setDefaultLayout()
        }
        .onChange(of: defaultListColumnCount) {
            guard !Defaults[.Customization.Library.rememberLayout] else { return }
            setDefaultLayout()
        }
        .onChange(of: viewModel.filterViewModel?.currentFilters) { _, newValue in
            guard let newValue, let id = viewModel.parent?.id else { return }

            if Defaults[.Customization.Library.rememberSort] {
                let newStoredFilters = StoredValues[.User.libraryFilters(parentID: id)]
                    .mutating(\.sortBy, with: newValue.sortBy)
                    .mutating(\.sortOrder, with: newValue.sortOrder)

                StoredValues[.User.libraryFilters(parentID: id)] = newStoredFilters
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
    }
}

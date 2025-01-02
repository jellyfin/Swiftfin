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

// TODO: need to think about better design for views that may not support current library display type
//       - ex: channels/albums when in portrait/landscape
//       - just have the supported view embedded in a container view?
// TODO: could bottom (defaults + stored) `onChange` copies be cleaned up?
//       - more could be cleaned up if there was a "switcher" property wrapper that takes two
//         sources and a switch and holds the current expected value
//       - or if Defaults values were moved to StoredValues and each key would return/respond to
//         what values they should have
// TODO: when there are no filters sometimes navigation bar will be clear until popped back to

/*
 Note: Currently, it is a conscious decision to not have grid posters have subtitle content.
       This is due to episodes, which have their `S_E_` subtitles, and these can be alongside
       other items that don't have a subtitle which requires the entire library to implement
       subtitle content but that doesn't look appealing. Until a solution arrives grid posters
       will not have subtitle content.
       There should be a solution since there are contexts where subtitles are desirable and/or
       we can have subtitle content for other items.

 Note: For `rememberLayout` and `rememberSort`, there are quirks for observing changes while a
       library is open and the setting has been changed. For simplicity, do not enforce observing
       changes and doing proper updates since there is complexity with what "actual" settings
       should be applied.
 */

struct PagingLibraryView<Element: Poster>: View {

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

    @Default(.Customization.Library.letterPickerEnabled)
    private var letterPickerEnabled
    @Default(.Customization.Library.letterPickerOrientation)
    private var letterPickerOrientation

    @EnvironmentObject
    private var router: LibraryCoordinator<Element>.Router

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

    // MARK: init

    init(viewModel: PagingLibraryViewModel<Element>) {

        // have to set these properties manually to get proper initial layout

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

        if UIDevice.isPhone {
            layout = Self.phoneLayout(
                posterType: initialPosterType,
                viewType: initialDisplayType
            )
        } else {
            layout = Self.padLayout(
                posterType: initialPosterType,
                viewType: initialDisplayType,
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
        case .person:
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

    // TODO: rename old "viewType" paramter to "displayType" and sort

    private static func padLayout(
        posterType: PosterDisplayType,
        viewType: LibraryDisplayType,
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
        posterType: PosterDisplayType,
        viewType: LibraryDisplayType
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

    // Note: if parent is a folders then other items will have labels,
    //       so an empty content view is necessary

    @ViewBuilder
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
            .onSelect {
                onSelect(item)
            }
    }

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
            .onSelect {
                onSelect(item)
            }
    }

    @ViewBuilder
    private func listItemView(item: Element, posterType: PosterDisplayType) -> some View {
        LibraryRow(item: item, posterType: posterType)
            .onSelect {
                onSelect(item)
            }
    }

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
            }
    }

    @ViewBuilder
    private var gridView: some View {
        CollectionVGrid(
            uniqueElements: viewModel.elements,
            id: \.unwrappedIDHashOrZero,
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
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.send(.getNextPage)
        }
        .proxy(collectionVGridProxy)
        .scrollIndicatorsVisible(false)
    }

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
            DelayedProgressView()
        default:
            AssertionFailureView("Expected view for unexpected state")
        }
    }

    @ViewBuilder
    private var contentView: some View {
        if letterPickerEnabled, let filterViewModel = viewModel.filterViewModel {
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
    }

    // MARK: body

    // TODO: becoming too large for typechecker during development, should break up somehow

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .content, .initial, .refreshing:
                contentView
            case let .error(error):
                errorView(with: error)
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea()
        .onSizeChanged { _, safeArea in
            self.safeArea = safeArea
        }
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
        .onChange(of: defaultDisplayType) { newValue in
            guard !Defaults[.Customization.Library.rememberLayout] else { return }

            if UIDevice.isPhone {
                layout = Self.phoneLayout(
                    posterType: defaultPosterType,
                    viewType: newValue
                )
            } else {
                layout = Self.padLayout(
                    posterType: defaultPosterType,
                    viewType: newValue,
                    listColumnCount: defaultListColumnCount
                )
            }
        }
        .onChange(of: defaultListColumnCount) { newValue in
            guard !Defaults[.Customization.Library.rememberLayout] else { return }

            if UIDevice.isPad {
                layout = Self.padLayout(
                    posterType: defaultPosterType,
                    viewType: defaultDisplayType,
                    listColumnCount: newValue
                )
            }
        }
        .onChange(of: defaultPosterType) { newValue in
            guard !Defaults[.Customization.Library.rememberLayout] else { return }

            if UIDevice.isPhone {
                if defaultDisplayType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.phoneLayout(
                        posterType: newValue,
                        viewType: defaultDisplayType
                    )
                }
            } else {
                if defaultDisplayType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.padLayout(
                        posterType: newValue,
                        viewType: defaultDisplayType,
                        listColumnCount: defaultListColumnCount
                    )
                }
            }
        }
        .onChange(of: displayType) { newValue in
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
                    viewType: displayType,
                    listColumnCount: newValue
                )
            }
        }
        .onChange(of: posterType) { newValue in
            if UIDevice.isPhone {
                if displayType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.phoneLayout(
                        posterType: newValue,
                        viewType: displayType
                    )
                }
            } else {
                if displayType == .list {
                    collectionVGridProxy.layout()
                } else {
                    layout = Self.padLayout(
                        posterType: newValue,
                        viewType: displayType,
                        listColumnCount: listColumnCount
                    )
                }
            }
        }
        .onChange(of: rememberLayout) { newValue in
            let newDisplayType = newValue ? displayType : defaultDisplayType
            let newListColumnCount = newValue ? listColumnCount : defaultListColumnCount
            let newPosterType = newValue ? posterType : defaultPosterType

            if UIDevice.isPhone {
                layout = Self.phoneLayout(
                    posterType: newPosterType,
                    viewType: newDisplayType
                )
            } else {
                layout = Self.padLayout(
                    posterType: newPosterType,
                    viewType: newDisplayType,
                    listColumnCount: newListColumnCount
                )
            }
        }
        .onChange(of: viewModel.filterViewModel?.currentFilters) { newValue in
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
        .navigationBarMenuButton(
            isLoading: viewModel.backgroundStates.contains(.gettingNextPage)
        ) {
            if Defaults[.Customization.Library.rememberLayout] {
                LibraryViewTypeToggle(
                    posterType: $posterType,
                    viewType: $displayType,
                    listColumnCount: $listColumnCount
                )
            } else {
                LibraryViewTypeToggle(
                    posterType: $defaultPosterType,
                    viewType: $defaultDisplayType,
                    listColumnCount: $defaultListColumnCount
                )
            }

            Button(L10n.random, systemImage: "dice.fill") {
                viewModel.send(.getRandomItem)
            }
            .disabled(viewModel.elements.isEmpty)
        }
    }
}

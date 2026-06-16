//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import SwiftUI

struct PagingLibraryView<Library: PagingLibrary>: View where Library.Element: LibraryElement {

    typealias Element = Library.Element

    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters
    @Default(.Customization.Library.rememberLayout)
    private var rememberIndividualLibraryStyle

    @ForTypeInEnvironment<Element.Type, (Any) -> (LibraryStyle, Binding<LibraryStyle>?)>(\.libraryStyleRegistry)
    private var libraryStyleRegistry

    @Namespace
    private var namespace

    @Router
    private var router

    @StateObject
    private var gridProxy = CollectionVGridProxy()
    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    @State
    private var collectedMenuGroups: [MenuContentGroup] = []

    @StoredValue(.User.libraryStyle(id: nil))
    private var defaultLibraryStyle: LibraryStyle
    @StoredValue
    private var parentLibraryStyle: LibraryStyle

    private var libraryStyle: LibraryStyle {
        libraryStyleRegistry?(Element.self).0 ?? storedLibraryStyle
    }

    private var libraryStyleBinding: Binding<LibraryStyle> {
        libraryStyleRegistry?(Element.self).1 ?? storedLibraryStyleBinding
    }

    private var storedLibraryStyle: LibraryStyle {
        rememberIndividualLibraryStyle ? parentLibraryStyle : defaultLibraryStyle
    }

    private var storedLibraryStyleBinding: Binding<LibraryStyle> {
        rememberIndividualLibraryStyle ? $parentLibraryStyle : $defaultLibraryStyle
    }

    init(library: Library) {
        self._parentLibraryStyle = StoredValue(.User.libraryStyle(id: library.parent.pagingLibraryID))
        self._viewModel = StateObject(wrappedValue: PagingLibraryViewModel(library: library))
    }

    @ViewBuilder
    private var elementsView: some View {
        CollectionVGrid(
            uniqueElements: viewModel.displayedElements,
            layout: Element.layout(for: libraryStyle)
        ) { element in
            switch libraryStyle.displayType {
            case .grid:
                element.makeGridBody(libraryStyle: libraryStyle)
            case .list:
                element.makeListBody(libraryStyle: libraryStyle)
            }
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            if viewModel.isSearchActive {
                viewModel.getNextSearchPage()
            } else {
                viewModel.getNextPage()
            }
        }
        .proxy(gridProxy)
        .scrollIndicators(.hidden)
    }

    var body: some View {
        viewModel.library.makeLibraryBody(viewModel: viewModel) {
            ZStack {
                switch viewModel.state {
                case .initial, .refreshing:
                    ProgressView()
                case .content:
                    if viewModel.isSearchActive, viewModel.background.is(.searching) {
                        ProgressView()
                    } else if viewModel.displayedElements.isEmpty {
                        ContentUnavailableView(
                            viewModel.isSearchActive ? L10n.noResults.localizedCapitalized : L10n.noItems.localizedCapitalized,
                            systemImage: viewModel.isSearchActive ? "magnifyingglass" : "rectangle.on.rectangle.slash"
                        )
                    } else {
                        elementsView
                            .libraryStyle(for: Element.self) { _, _ in
                                (storedLibraryStyle, storedLibraryStyleBinding)
                            }
                    }
                case .error:
                    viewModel.error.map(ErrorView.init)
                }
            }
        }
        .animation(.linear(duration: 0.2), value: viewModel.background.is(.gettingNextPage))
        .animation(.linear(duration: 0.2), value: viewModel.background.is(.searching))
        .animation(.linear(duration: 0.2), value: viewModel.elements)
        .animation(.linear(duration: 0.2), value: viewModel.searchElements)
        .letterPickerBar(filterViewModel: viewModel.filterViewModel)
        .navigationTitle(viewModel.library.parent.displayTitle)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .preference(key: MenuContentKey.self) {
            MenuContentGroup(id: "library-style") {
                LibraryStyleSection(libraryStyle: libraryStyleBinding)
            }

            viewModel.library.menuContent(environment: $viewModel.environment)

            MenuContentGroup(id: "retrieve-random-element") {
                Button(L10n.random, systemImage: "dice.fill") {
                    viewModel.getRandomItem()
                }
            }
        }
        #if os(iOS)
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.gettingNextPage) || viewModel.background.is(.gettingNextSearchPage)
        ) {}
        #else
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    if viewModel.background.is(.gettingNextPage) || viewModel.background.is(.gettingNextSearchPage) {
                        ProgressView()
                    }

                    if collectedMenuGroups.isNotEmpty {
                        Menu(L10n.options, systemImage: "ellipsis.circle") {
                            ForEach(collectedMenuGroups) { group in
                                group.content
                            }
                        }
                    }
                }
            }
            .onPreferenceChange(MenuContentKey.self) { newGroups in
                collectedMenuGroups = newGroups
            }
        #endif
            .refreshable {
                    viewModel.refresh()
                }
        #if os(iOS)
                .ifLet(viewModel.filterViewModel) { view, filterViewModel in
                    view.navigationBarFilterDrawer(
                        viewModel: filterViewModel,
                        types: enabledDrawerFilters
                    )
                }
        #endif
                .backport
                    .onChange(of: viewModel.environment) {
                        viewModel.refresh()
                    }
                    .backport
                    .onChange(of: viewModel.filterViewModel?.currentFilters) { _, newFilters in
                        guard let newFilters,
                              let id = viewModel.library.parent.id,
                              Defaults[.Customization.Library.rememberSort]
                        else { return }

                        let storedFilters = StoredValues[.User.libraryFilters(parentID: id)]
                            .mutating(\.sortBy, with: newFilters.sortBy)
                            .mutating(\.sortOrder, with: newFilters.sortOrder)

                        StoredValues[.User.libraryFilters(parentID: id)] = storedFilters
                    }
                    .backport
                    .onChange(of: libraryStyle) { oldStyle, newStyle in
                        if Element.layout(for: oldStyle) == Element.layout(for: newStyle) {
                            gridProxy.layout()
                        }
                    }
                    .onReceive(viewModel.events) { event in
                        switch event {
                        case let .gotRandomItem(element):
                            element.libraryDidSelectElement(router: router, in: namespace)
                        }
                    }
                    .onFirstAppear {
                        viewModel.refresh()
                    }
    }
}

private struct LibraryStyleSection: View {

    @StateObject
    private var box: BindingBox<LibraryStyle>

    private var libraryStyle: Binding<LibraryStyle> {
        $box.value
    }

    init(libraryStyle: Binding<LibraryStyle>) {
        self._box = StateObject(wrappedValue: BindingBox(source: libraryStyle))
    }

    var body: some View {
        Picker(selection: libraryStyle.displayType) {
            ForEach(LibraryDisplayType.allCases, id: \.self) { displayType in
                Label(
                    displayType.displayTitle,
                    systemImage: displayType.systemImage
                )
                .tag(displayType)
            }
        } label: {
            Text(L10n.layout)

            Text(libraryStyle.wrappedValue.displayType.displayTitle)

            Image(systemName: libraryStyle.wrappedValue.displayType.systemImage)
        }
        .pickerStyle(.menu)

        if libraryStyle.wrappedValue.displayType == .list, UIDevice.isPad {
            // TODO: tvOS
//            Stepper(
//                L10n.columnsWithCount(libraryStyle.wrappedValue.listColumnCount),
//                value: libraryStyle.listColumnCount,
//                in: 1 ... 3
//            )
        }

        Picker(selection: libraryStyle.posterDisplayType) {
            ForEach(PosterDisplayType.allCases, id: \.self) { displayType in
                Text(displayType.displayTitle)
                    .tag(displayType)
            }
        } label: {
            Text(L10n.posters)

            Text(libraryStyle.wrappedValue.posterDisplayType.displayTitle)
        }
        .pickerStyle(.menu)
    }
}

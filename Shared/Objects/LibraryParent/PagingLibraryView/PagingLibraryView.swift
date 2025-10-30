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

struct PagingLibraryView<Library: PagingLibrary>: View where Library.Element: LibraryElement {

    typealias Element = Library.Element

    @Default(.Customization.Library.enabledDrawerFilters)
    private var enabledDrawerFilters
    @Default(.Customization.Library.rememberLayout)
    private var rememberIndividualLibraryStyle

    @StoredValue(.User.libraryStyle(id: nil))
    private var defaultLibraryStyle: LibraryStyle
    @StoredValue
    private var parentLibraryStyle: LibraryStyle

    @ForTypeInEnvironment<Element.Type, (Any) -> (LibraryStyle, Binding<LibraryStyle>?)>(\.libraryStyleRegistry)
    private var libraryStyleRegistry

    @Namespace
    private var namespace

    @Router
    private var router

    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    private var libraryStyle: LibraryStyle {
        libraryStyleRegistry?(Element.self).0 ?? .default
    }

    init(library: Library) {
        self._parentLibraryStyle = StoredValue(.User.libraryStyle(id: library.parent.libraryID))
        self._viewModel = StateObject(wrappedValue: PagingLibraryViewModel(library: library))
    }

    @ViewBuilder
    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.refresh()
            }
    }

//    @ViewBuilder
//    private func WithFilters(
//        @ViewBuilder content: () -> some View
//    ) -> some View {
//        if let filterViewModel = viewModel.library.filterViewModel {
//            content()
//                .navigationBarFilterDrawer(
//                    viewModel: filterViewModel,
//                    types: enabledDrawerFilters
//                ) { parameters in
//                    router.route(to: .filter(type: parameters.type, viewModel: parameters.viewModel))
//                }
//                .onReceive(filterViewModel.currentFiltersDebounced) { _ in
//                    viewModel.refresh()
//                }
//        } else {
//        content()
//        }
//    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .initial, .refreshing:
            ProgressView()
                .progressViewStyle(.circular)
        case .content:
            if viewModel.elements.isEmpty {
                Text(L10n.noResults)
            } else {
                ElementsView(viewModel: viewModel)
                    .ignoresSafeArea()
                    .libraryStyle(for: Element.self) { environment, _ in
                        if rememberIndividualLibraryStyle {
                            return (parentLibraryStyle, $parentLibraryStyle)
                        } else {
                            return environment
                        }
                    }
            }
        case .error:
            viewModel.error.map(errorView)
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            viewModel.library.makeLibraryBody(content: contentView)
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea()
        .navigationTitle(viewModel.library.parent.displayTitle)
        .navigationBarTitleDisplayMode(.inline)
        .backport
        .onChange(of: viewModel.environment) { _, _ in
            viewModel.refresh()
        }
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.refresh()
            }
        }
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.retrievingNextPage)
        ) {}
    }
}

extension PagingLibraryView {

    // TODO: breakout into own content view?
    struct ElementsView: View {

        @ForTypeInEnvironment<Element.Type, (Any) -> (LibraryStyle, Binding<LibraryStyle>?)>(\.libraryStyleRegistry)
        private var libraryStyleRegistry

        @Namespace
        private var namespace

        @ObservedObject
        private var viewModel: PagingLibraryViewModel<Library>

        @Router
        private var router

        @StateObject
        private var collectionVGridProxy: CollectionVGridProxy = .init()

        private var libraryStyleBinding: Binding<LibraryStyle>?

        init(
            viewModel: PagingLibraryViewModel<Library>
        ) {
            self._libraryStyleRegistry = ForTypeInEnvironment(\.libraryStyleRegistry)
            self.viewModel = viewModel

            if let libraryStyleBinding {
                self.libraryStyleBinding = libraryStyleBinding
            }
        }

        #if os(iOS)
        private var layout: CollectionVGridLayout {
            if UIDevice.isPhone {
                phoneLayout
            } else {
                padLayout
            }
        }

        private var padLayout: CollectionVGridLayout {
            switch (libraryStyle.posterDisplayType, libraryStyle.displayType) {
            case (.landscape, .grid):
                .minWidth(220)
            case (.portrait, .grid), (.square, .grid):
                .minWidth(140)
            case (_, .list):
                .columns(libraryStyle.listColumnCount, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            }
        }

        private var phoneLayout: CollectionVGridLayout {
            switch (libraryStyle.posterDisplayType, libraryStyle.displayType) {
            case (.landscape, .grid):
                .columns(2)
            case (.portrait, .grid):
                .columns(3)
            case (.square, .grid):
                .columns(3)
            case (_, .list):
                .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
            }
        }
        #else
        private var layout: CollectionVGridLayout {
            switch (libraryStyle.posterDisplayType, libraryStyle.displayType) {
            case (.landscape, .grid):
                return .columns(
                    5,
                    insets: EdgeInsets.edgeInsets,
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            case (.portrait, .grid), (.square, .grid):
                return .columns(
                    7,
                    insets: EdgeInsets.edgeInsets,
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            case (_, .list):
                return .columns(
                    libraryStyle.listColumnCount,
                    insets: EdgeInsets.edgeInsets,
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            }
        }
        #endif

        private var evaluatedStyle: (LibraryStyle, Binding<LibraryStyle>?) {
            libraryStyleRegistry?(Element.self) ?? (.default, nil)
        }

        private var libraryStyle: LibraryStyle {
            evaluatedStyle.0
        }

        private func select(element: Element, in namespace: Namespace.ID) {
            switch element {
            case let element as BaseItemDto:
                select(item: element, in: namespace)
            case let element as BaseItemPerson:
                select(item: BaseItemDto(person: element), in: namespace)
            default:
                assertionFailure("Used an unexpected type within a `PagingLibaryView`?")
            }
        }

        private func select(item: BaseItemDto, in namespace: Namespace.ID) {
            switch item.type {
            case .collectionFolder, .folder, .userView:
                let library = PagingItemLibrary(parent: item)
                router.route(to: .library(library: library), in: namespace)
            default:
                router.route(to: .item(item: item), in: namespace)
            }
        }

        @ViewBuilder
        private func gridItemView(
            element: Element
        ) -> some View {
            PosterButton(
                item: element,
                type: libraryStyle.posterDisplayType
            ) { namespace in
                select(element: element, in: namespace)
            }
            //            .posterStyle(for: BaseItemDto.self) { environment, _ in
            //                var environment = environment
            //                environment.useParentImages = false
            //                return environment
            //            }
            //        } label: {
            //            if item.showTitle {
            //                PosterButton<Element>.TitleContentView(title: item.displayTitle)
            //                    .lineLimit(1, reservesSpace: true)
            //            } else if viewModel.parent?.libraryType == .folder {
            //                PosterButton<Element>.TitleContentView(title: item.displayTitle)
            //                    .lineLimit(1, reservesSpace: true)
            //                    .hidden()
            //            }
            //        }
        }

        @ViewBuilder
        private func listItemView(
            element: Element
        ) -> some View {
            LibraryRow(
                item: element,
                posterType: libraryStyle.posterDisplayType
            ) { namespace in
                select(element: element, in: namespace)
            }
        }

        var body: some View {
            CollectionVGrid(
                uniqueElements: viewModel.elements,
                id: \.unwrappedIDHashOrZero,
                layout: layout
            ) { element, _ in
                switch libraryStyle.displayType {
                case .grid:
                    gridItemView(element: element)
                case .list:
                    listItemView(element: element)
                }
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                viewModel.retrieveNextPage()
            }
            .proxy(collectionVGridProxy)
            .scrollIndicators(.hidden)
            .posterStyle(for: Element.self) { environment, _ in
                var environment = environment
                environment.displayType = libraryStyle.posterDisplayType
                return environment
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .retrievedRandomElement(item):
                    switch item {
                    case let item as BaseItemDto:
                        select(item: item, in: namespace)
                    case let item as BaseItemPerson:
                        select(item: BaseItemDto(person: item), in: namespace)
                    default:
                        assertionFailure("Used an unexpected type within a `PagingLibaryView`?")
                    }
                }
            }
            .preference(key: MenuContentKey.self) {
                if let libraryStyleBinding = evaluatedStyle.1 {
                    MenuContentGroup(
                        id: "library-style"
                    ) {
                        LibraryStyleSection(libraryStyle: libraryStyleBinding)
                    }
                }

                viewModel.library.menuContent(environment: $viewModel.environment)

                MenuContentGroup(
                    id: "retrieve-random-element"
                ) {
                    Button(L10n.random, systemImage: "dice.fill") {
                        viewModel.retrieveRandomElement()
                    }
                }
            }
        }
    }
}

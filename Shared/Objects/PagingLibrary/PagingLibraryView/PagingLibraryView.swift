//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
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
    private var contentView: some View {
        switch viewModel.state {
        case .initial, .refreshing:
            ProgressView()
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
            viewModel.error.map(ErrorView.init)
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            viewModel.library.makeLibraryBody(content: contentView, state: viewModel.state)
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
        #if os(iOS)
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.retrievingNextPage)
        ) {}
        #endif
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

        private var resolvedStyle: (LibraryStyle, Binding<LibraryStyle>?) {
            libraryStyleRegistry?(Element.self) ?? (.default, nil)
        }

        private var layout: CollectionVGridLayout {
            Element.layout(for: libraryStyle)
        }

        private var libraryStyle: LibraryStyle {
            resolvedStyle.0
        }

        var body: some View {
            CollectionVGrid(
                uniqueElements: viewModel.elements,
                layout: layout
            ) { element, _ in
                switch libraryStyle.displayType {
                case .grid:
                    element.makeGridBody(libraryStyle: libraryStyle)
                        .withViewContext(.isThumb)
                case .list:
                    element.makeListBody(libraryStyle: libraryStyle)
                        .withViewContext(.isThumb)
                }
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                viewModel.retrieveNextPage()
            }
            .scrollIndicators(.hidden)
            .onReceive(viewModel.events) { event in
                switch event {
                case let .retrievedRandomElement(element):
                    element.libraryDidSelectElement(router: router, in: namespace)
                }
            }
            .preference(key: MenuContentKey.self) {
                if let libraryStyleBinding = resolvedStyle.1 {
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

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

    @Default(.Customization.Library.rememberLayout)
    private var rememberIndividualLibraryStyle

    @Namespace
    private var namespace

    @Router
    private var router

    @ForTypeInEnvironment<Element.Type, (Any) -> (LibraryStyle, Binding<LibraryStyle>?)>(\.libraryStyleRegistry)
    private var libraryStyleRegistry

    @StateObject
    private var gridProxy = CollectionVGridProxy()
    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

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
            uniqueElements: viewModel.elements,
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
            viewModel.getNextPage()
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
                    if viewModel.elements.isEmpty {
                        ContentUnavailableView(L10n.noItems.localizedCapitalized, systemImage: "rectangle.on.rectangle.slash")
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
        .animation(.linear(duration: 0.2), value: viewModel.elements)
        .navigationTitle(viewModel.library.parent.displayTitle)
        .backport
        .toolbarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {

                if viewModel.background.is(.gettingNextPage) {
                    ProgressView()
                }

                Menu(L10n.options, systemImage: "ellipsis.circle") {
                    LibraryStyleSection(libraryStyle: libraryStyleBinding)

                    Button(L10n.random, systemImage: "dice.fill") {
                        viewModel.getRandomItem()
                    }
                }
            }
        }
        .refreshable {
            viewModel.refresh()
        }
        .backport
        .onChange(of: viewModel.environment) {
            viewModel.refresh()
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

    @Binding
    var libraryStyle: LibraryStyle

    var body: some View {
        Picker(L10n.layout, selection: $libraryStyle.displayType) {
            ForEach(LibraryDisplayType.allCases, id: \.self) { displayType in
                Label(displayType.displayTitle, systemImage: displayType.systemImage)
                    .tag(displayType)
            }
        }

        Picker(L10n.posters, selection: $libraryStyle.posterDisplayType) {
            ForEach(PosterDisplayType.supportedCases, id: \.self) { posterDisplayType in
                Label(posterDisplayType.displayTitle, systemImage: posterDisplayType.systemImage)
                    .tag(posterDisplayType)
            }
        }
    }
}

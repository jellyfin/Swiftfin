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

    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    @StoredValue(.User.libraryStyle(id: nil))
    private var defaultLibraryStyle: LibraryStyle
    @StoredValue
    private var parentLibraryStyle: LibraryStyle

    private var libraryStyle: LibraryStyle {
        rememberIndividualLibraryStyle ? parentLibraryStyle : defaultLibraryStyle
    }

    private var libraryStyleBinding: Binding<LibraryStyle> {
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
        .scrollIndicators(.hidden)
    }

    @ViewBuilder
    private var contentView: some View {
        switch viewModel.state {
        case .initial, .refreshing:
            ProgressView()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        case .content:
            if viewModel.elements.isEmpty {
                Text(L10n.noResults)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                elementsView
            }
        case .error:
            viewModel.error.map(ErrorView.init)
        }
    }

    var body: some View {
        contentView
            .animation(.linear(duration: 0.2), value: viewModel.background.is(.gettingNextPage))
            .animation(.linear(duration: 0.2), value: viewModel.elements)
            .navigationTitle(viewModel.library.parent.displayTitle)
            .backport
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        LibraryStyleSection(libraryStyle: libraryStyleBinding)

                        Button(L10n.random, systemImage: "dice.fill") {
                            viewModel.getRandomItem()
                        }
                    } label: {
                        if viewModel.background.is(.gettingNextPage) {
                            ProgressView()
                        } else {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
            }
            .refreshable {
                viewModel.refresh()
            }
            .backport.onChange(of: viewModel.environment) {
                viewModel.refresh()
            }
            .onReceive(viewModel.events) { event in
                switch event {
                case let .gotRandomItem(element):
                    element.libraryDidSelectElement(router: router, in: namespace)
                }
            }
            .onFirstAppear {
                if case .initial = viewModel.state {
                    viewModel.refresh()
                }
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

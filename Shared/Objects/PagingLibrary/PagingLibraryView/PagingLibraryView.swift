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
    @Default(.Customization.Library.style)
    private var defaultLibraryStyle

    @Namespace
    private var namespace

    @Router
    private var router

    @State
    private var isSafeAreaBarApplied: Bool = false

    @State
    private var slotHeights: [Element.ID: CGFloat] = [:]

    @StateObject
    private var gridProxy = CollectionVGridProxy()
    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    @StoredValue
    private var parentLibraryStyle: LibraryStyle

    @TabItemSelected
    private var tabItemSelected

    private var libraryStyleOptions: LibraryStyleOptions {
        viewModel.libraryStyleOptions
    }

    private var libraryStyle: LibraryStyle {
        libraryStyleOptions.normalized(storedLibraryStyle)
    }

    private var isLibraryStyleSectionVisible: Bool {
        libraryStyleOptions.hasVisibleControls ||
            (
                libraryStyle.displayType == .list &&
                    UIDevice.isPad &&
                    libraryStyleOptions.displayTypes.contains(.list)
            )
    }

    private var storedLibraryStyle: LibraryStyle {
        rememberIndividualLibraryStyle ? parentLibraryStyle : defaultLibraryStyle
    }

    private var storedLibraryStyleBinding: Binding<LibraryStyle> {
        rememberIndividualLibraryStyle ? $parentLibraryStyle : $defaultLibraryStyle
    }

    init(library: Library) {
        self._parentLibraryStyle = StoredValue(.User.libraryStyle(id: library.parent.pagingLibraryID))
        let viewModel = PagingLibraryViewModel(library: library)
        if Element.self == ItemEntry.self {
            viewModel.maximumLoadedPages = 5
        }
        self._viewModel = StateObject(wrappedValue: viewModel)
    }

    @ViewBuilder
    private var elementsView: some View {
        AlternateLayoutView {
            Color.clear
        } content: { frame in

            let insets: EdgeInsets = if #available(iOS 26, *), isSafeAreaBarApplied {
                frame.safeAreaInsets + 10
            } else {
                .zero + 10
            }

            CollectionVGrid(
                uniqueElements: viewModel.displayedSlots,
                layout: Element.layout(
                    for: libraryStyle,
                    options: libraryStyleOptions,
                    insets: insets
                )
            ) { slot in
                Group {
                    if let element = slot.element {
                        element.makeBody(libraryStyle: libraryStyle)
                            .onGeometryChange(for: CGFloat.self) { $0.size.height } action: { height in
                                if slotHeights[slot.id] != height {
                                    slotHeights[slot.id] = height
                                }
                            }
                    } else {
                        Button {
                            viewModel.reloadPage(at: slot.offset)
                        } label: {
                            ZStack {
                                Color.secondarySystemFill
                                if viewModel.failedPageOffsets.contains(slot.offset) {
                                    Image(systemName: "arrow.clockwise")
                                } else {
                                    ProgressView()
                                }
                            }
                            .frame(height: slotHeights[slot.id] ?? 160)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onAppear { viewModel.pageDidAppear(slot) }
                .onDisappear { viewModel.pageDidDisappear(slot) }
            }
            .onReachedBottomEdge(offset: .offset(300)) {
                if viewModel.isSearchActive {
                    viewModel.getNextSearchPage()
                } else {
                    viewModel.getNextPage()
                }
            }
            .proxy(gridProxy)
            .onRefresh {
                await viewModel.background.refresh()
            }
            .ignoresSafeArea(edges: .vertical)
        }
        .scrollIndicators(.hidden)
        .withViewContext(.isListRowSeparatorVisible)
        .withViewContext(.isThumb)
        .onReceive(tabItemSelected) { event in
            if event.isRepeat, event.isRoot {
                gridProxy.scrollToTop(animated: true)
            }
        }
    }

    @ViewBuilder
    private var menuContent: some View {
        if isLibraryStyleSectionVisible {
            LibraryStyleSection(
                libraryStyle: storedLibraryStyleBinding,
                options: libraryStyleOptions
            )
        }

        viewModel.library.makeMenuContent(environment: $viewModel.environment)

        Button(L10n.random, systemImage: "dice.fill") {
            viewModel.getRandomItem()
        }
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
                    } else if viewModel.displayedSlots.isEmpty {
                        ContentUnavailableView(
                            viewModel.isSearchActive ? L10n.noResults.localizedCapitalized : L10n.noItems.localizedCapitalized,
                            systemImage: viewModel.isSearchActive ? "magnifyingglass" : "rectangle.on.rectangle.slash"
                        )
                        .focusable()
                    } else {
                        elementsView
                    }
                case .error:
                    viewModel.error.map(ErrorView.init)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .animation(.linear(duration: 0.2), value: viewModel.background.is(.gettingNextPage))
        .animation(.linear(duration: 0.2), value: viewModel.background.is(.searching))
        .animation(.linear(duration: 0.2), value: viewModel.elements)
        .animation(.linear(duration: 0.2), value: viewModel.searchElements)
        .navigationTitle(viewModel.library.parent.displayTitle)
        .errorMessage($viewModel.error)
        .onPreferenceChange(IsSafeAreaBarApplied.self) { newValue in
            isSafeAreaBarApplied = newValue
        }
        #if os(iOS)
        .toolbarTitleDisplayMode(router.isRootOfPath ? .inlineLarge : .inline)
        #endif
        .onChange(of: viewModel.environment) {
            viewModel.refreshForEnvironmentChange()
        }
        .onChange(of: viewModel.displayedSlots.map(\.id)) { _, ids in
            let retained = Set(ids)
            slotHeights = slotHeights.filter { retained.contains($0.key) }
        }
        .onChange(of: libraryStyle) { oldStyle, newStyle in
            if Element.layout(for: oldStyle, options: libraryStyleOptions, insets: .zero) ==
                Element.layout(for: newStyle, options: libraryStyleOptions, insets: .zero)
            {
                gridProxy.redraw()
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
        #if os(iOS)
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.gettingNextPage) || viewModel.background.is(.gettingNextSearchPage)
        ) {
            menuContent
        }
        #endif
    }
}

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

    private enum Focus: String {

        case firstElement = "pagingLibrary-firstElement"
    }

    typealias Element = Library.Element

    @AdaptiveLayout
    private var viewLayout

    @Default(.Customization.Library.rememberLayout)
    private var rememberIndividualLibraryStyle
    @Default(.Customization.Library.style)
    private var defaultLibraryStyle

    @Environment(\.frameForParentView)
    private var frameForParentView

    @Namespace
    private var namespace

    @Router
    private var router

    @StateObject
    private var focusCoordinator = FocusCoordinator(waitingFor: Focus.firstElement.rawValue)
    @StateObject
    private var gridProxy = CollectionVGridProxy()
    @StateObject
    private var viewModel: PagingLibraryViewModel<Library>

    @StoredValue
    private var parentLibraryStyle: LibraryStyle

    @TabItemSelected
    private var tabItemSelected

    private let displayTitle: String?

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
                    libraryStyleOptions.displayTypes.contains(.list) &&
                    viewLayout.canAdjustLibraryListColumns
            )
    }

    private var storedLibraryStyle: LibraryStyle {
        rememberIndividualLibraryStyle ? parentLibraryStyle : defaultLibraryStyle
    }

    private var storedLibraryStyleBinding: Binding<LibraryStyle> {
        rememberIndividualLibraryStyle ? $parentLibraryStyle : $defaultLibraryStyle
    }

    init(library: Library, displayTitle: String? = nil) {
        self.displayTitle = displayTitle
        self._parentLibraryStyle = StoredValue(.User.libraryStyle(id: library.parent.pagingLibraryID))
        self._viewModel = StateObject(wrappedValue: PagingLibraryViewModel(library: library))
    }

    private func contentInsets(for frame: GeometryProxy) -> EdgeInsets {
        #if os(tvOS)
        // The collection disables automatic adjustment, so include both the local
        // safe area (including filter bars) and the tab's measured top inset.
        var insets = frame.safeAreaInsets
        insets.top = max(insets.top, frameForParentView[.tabView]?.safeAreaInsets.top ?? 0)
        return insets + viewLayout.itemSpacing
        #else
        let horizontalSpacing = libraryStyle.displayType == .list ? 0 : viewLayout.itemSpacing
        return EdgeInsets(
            top: frame.safeAreaInsets.top + viewLayout.itemSpacing,
            leading: horizontalSpacing,
            bottom: frame.safeAreaInsets.bottom + viewLayout.itemSpacing,
            trailing: horizontalSpacing
        )
        #endif
    }

    private var elementsView: some View {
        GeometryReader { geometry in

            CollectionVGrid(
                uniqueElements: viewModel.displayedElements,
                layout: Element.layout(
                    for: libraryStyle,
                    options: libraryStyleOptions,
                    insets: contentInsets(for: geometry),
                    viewLayout: viewLayout.resolving(size: geometry.size)
                )
            ) { element in
                element.makeBody(libraryStyle: libraryStyle)
                    #if os(tvOS)
                        .if(element.id == viewModel.displayedElements.first?.id) { view in
                            view
                                .coordinatedFocus(Focus.firstElement.rawValue)
                                .environmentObject(focusCoordinator)
                        }
                    #endif
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
            .contentInsetAdjustmentBehavior(.never)
            #if os(tvOS)
            .ignoresSafeArea()
            #else
            .ignoresSafeArea(edges: .vertical)
            #endif
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
                options: libraryStyleOptions,
                canAdjustListColumns: viewLayout.canAdjustLibraryListColumns
            )
        }

        viewModel.library.makeMenuContent(environment: $viewModel.environment)

        if let parent = viewModel.library.parent as? BaseItemDto {
            ShuffleButton(item: parent)
        }

        Button(L10n.random, systemImage: "dice.fill") {
            viewModel.getRandomItem()
        }
    }

    private var libraryContent: some View {
        viewModel.library.makeLibraryBody(viewModel: viewModel) {
            ZStack {
                switch viewModel.state {
                case .initial, .refreshing:
                    ProgressView()
                        #if os(tvOS)
                            .coordinatedFocus(.placeholder)
                        #endif

                case .content:
                    if viewModel.isSearchActive, viewModel.background.is(.searching) {
                        ProgressView()
                    } else if viewModel.displayedElements.isEmpty {
                        ContentUnavailableView(
                            viewModel.isSearchActive ? L10n.noResults.localizedCapitalized : L10n.noItems.localizedCapitalized,
                            systemImage: viewModel.isSearchActive ? "magnifyingglass" : "rectangle.on.rectangle.slash"
                        )
                        .focusable()
                        #if os(tvOS)
                        .coordinatedFocus(.fallback)
                        #endif
                    } else {
                        elementsView
                    }

                case .error:
                    viewModel.error.map(ErrorView.init)
                        #if os(tvOS)
                            .coordinatedFocus(.fallback)
                        #endif
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    var body: some View {
        Group {
            #if os(tvOS)
            libraryContent
            #else
            GeometryReader { geometry in
                let safeArea = frameForParentView[.navigationStack]?.safeAreaInsets ?? geometry.safeAreaInsets
                let horizontalInsets = EdgeInsets(
                    top: 0,
                    leading: safeArea.leading,
                    bottom: 0,
                    trailing: safeArea.trailing
                )

                libraryContent
                    .layoutContainer(size: CGSize(
                        width: max(0, geometry.size.width - horizontalInsets.leading - horizontalInsets.trailing),
                        height: geometry.size.height
                    ))
                    .padding(horizontalInsets)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                    .animation(.smooth(duration: 0.35), value: horizontalInsets)
            }
            .ignoresSafeArea(.container, edges: .horizontal)
            #endif
        }
        .animation(.linear(duration: 0.2), value: viewModel.background.is(.gettingNextPage))
        .animation(.linear(duration: 0.2), value: viewModel.background.is(.searching))
        .animation(.linear(duration: 0.2), value: viewModel.elements)
        .animation(.linear(duration: 0.2), value: viewModel.searchElements)
        .navigationTitle(displayTitle ?? viewModel.library.parent.displayTitle)
        .errorMessage($viewModel.error)
        #if os(iOS)
        .toolbarTitleDisplayMode(router.isRootOfPath ? .inlineLarge : .inline)
        #endif
        .onChange(of: viewModel.environment) {
            viewModel.refreshForEnvironmentChange()
        }
        .onChange(of: libraryStyle) {
            gridProxy.redraw()
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
        #if os(tvOS)
        .environmentObject(focusCoordinator)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                if let parent = viewModel.library.parent as? BaseItemDto {
                    ShuffleButton(item: parent)
                }
            }
        }
        #else
        .navigationBarMenuButton(
            isLoading: viewModel.background.is(.gettingNextPage) || viewModel.background.is(.gettingNextSearchPage)
        ) {
            menuContent
        }
        #endif
    }
}

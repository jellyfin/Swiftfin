//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct LibraryView: View {

    @Default(.Customization.Library.viewType)
    private var libraryViewType

    @Default(.Customization.Filters.libraryFilterDrawerButtons)
    private var filterDrawerButtonSelection

    @EnvironmentObject
    private var router: LibraryCoordinator.Router

    @StateObject
    var viewModel: LibraryViewModel
    
//    init(viewModel: LibraryViewModel) {
//        self._viewModel = StateObject(wrappedValue: viewModel)
//    }
    
    init(parent: LibraryParent, type: LibraryParentType, filters: ItemFilters) {
        self._viewModel = StateObject(
            wrappedValue: LibraryViewModel(
                parent: parent,
                type: type,
                filters: filters,
                saveFilters: false
            )
        )
    }

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }

    private func baseItemOnSelect(_ item: BaseItemDto) {
        switch item.type {
        case .collectionFolder, .folder:
            router.route(to: \.library, .init(parent: item, type: .folders, filters: .init()))
        default:
            router.route(to: \.item, item)
        }
    }

    @ViewBuilder
    private var libraryItemsView: some View {
        PagingLibraryView(viewModel: viewModel)
            .onSelect(baseItemOnSelect(_:))
            .ignoresSafeArea()
    }
    
    @ViewBuilder
    private var innerBody: some View {
        if viewModel.isLoading && viewModel.items.isEmpty {
            loadingView
        } else if viewModel.items.isEmpty {
            noResultsView
        } else {
            libraryItemsView
        }
    }

    var body: some View {
        innerBody
            .navigationTitle(viewModel.parent?.displayTitle ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .if(!filterDrawerButtonSelection.isEmpty) { view in
                view.navBarDrawer {
                    ScrollView(.horizontal, showsIndicators: false) {
                        FilterDrawerHStack(viewModel: viewModel.filterViewModel, filterDrawerButtonSelection: filterDrawerButtonSelection)
                            .onSelect { filterCoordinatorParameters in
                                router.route(to: \.filter, filterCoordinatorParameters)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 1)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .navigationBarTrailing) {
                    if viewModel.isLoading && !viewModel.items.isEmpty {
                        ProgressView()
                    }

                    Menu {
                        LibraryViewTypeToggle(libraryViewType: $libraryViewType)

                        RandomItemButton(viewModel: viewModel)
                            .onSelect { item in
                                if let item {
                                    router.route(to: \.item, item)
                                }
                            }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
            .onFirstAppear {
                <#code#>
            }
//            .task {
//                // SwiftUI doesn't have a single `onLoad` event, only when appearing.
//                // Only hard refresh on a fresh appearance, but not on a navigation pop.
//                guard viewModel.items.isEmpty else { return }
//                
//                do {
//                    try await viewModel.refresh()
//                    print("successfully refreshed")
//                } catch {
//                    print(error)
//                }
//            }
    }
}

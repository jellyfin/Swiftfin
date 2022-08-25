//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import SwiftUI

struct LibraryView: View {

    @EnvironmentObject
    private var libraryRouter: LibraryCoordinator.Router
    @ObservedObject
    var viewModel: LibraryViewModel

    private let defaultFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], tags: [], sortBy: [.name])

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }

    @ViewBuilder
    private var libraryItemsView: some View {
        CollectionView(items: viewModel.items) { _, item in
            PosterButton(item: item, type: .portrait)
                .onSelect { item in
                    libraryRouter.route(to: \.item, item)
                }
        }
        .layout { _, layoutEnvironment in
                .grid(
                    layoutEnvironment: layoutEnvironment,
                    layoutMode: .adaptive(withMinItemSize: PosterButtonWidth.portrait + (UIDevice.isIPad ? 10 : 0)))
        }
        .onBoundaryReached { boundary in
            if !viewModel.isLoading && boundary == .bottom {
                viewModel.requestNextPageAsync()
            }
        }
        .ignoresSafeArea()
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                loadingView
            } else if viewModel.items.isEmpty {
                noResultsView
            } else {
                libraryItemsView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                Button {
                    libraryRouter
                        .route(to: \.filter, (
                            filters: $viewModel.filters,
                            enabledFilterType: viewModel.enabledFilterType,
                            parentId: viewModel.parentID ?? ""
                        ))
                } label: {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                }
                .foregroundColor(viewModel.filters == defaultFilters ? .accentColor : Color(UIColor.systemOrange))

                Button {
                    libraryRouter.route(to: \.search, .init(parentID: viewModel.parentID))
                } label: {
                    Image(systemName: "magnifyingglass")
                }
            }
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI
import ASCollectionView

struct LibraryView: View {

    @EnvironmentObject
    private var libraryRouter: LibraryCoordinator.Router
    @StateObject
    var viewModel: LibraryViewModel

    let defaultFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], tags: [], sortBy: [.name])

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
        ASCollectionView(data: viewModel.items) { item, _ in
            PosterButton(item: item, type: .landscape)
                .onSelect { item in
                    libraryRouter.route(to: \.item, item)
                }
                .scaleItem(0.8)
        }
        .layout {
            .grid(
                layoutMode: .adaptive(withMinItemSize: 150),
                itemSpacing: 10,
                lineSpacing: 10)
        }
        .onReachedBoundary { boundary in
            if boundary == .bottom {
                if viewModel.hasNextPage {
                    viewModel.requestNextPageAsync()
                }
            }
        }
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.items.isEmpty {
                ProgressView()
            } else if !viewModel.items.isEmpty {
                libraryItemsView
            } else {
                noResultsView
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

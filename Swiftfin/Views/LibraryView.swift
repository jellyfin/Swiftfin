//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Stinsen
import SwiftUI

struct LibraryView: View {

    @EnvironmentObject
    private var libraryRouter: LibraryCoordinator.Router
    @StateObject
    var viewModel: LibraryViewModel
    var title: String

    // MARK: tracks for grid

    var defaultFilters = LibraryFilters(filters: [], sortOrder: [.ascending], withGenres: [], tags: [], sortBy: [.name])

    @State
    private var tracks: [GridItem] = Array(
        repeating: .init(.flexible(), alignment: .top),
        count: Int(UIScreen.main.bounds.size.width) / 125
    )

    func recalcTracks() {
        tracks = Array(repeating: .init(.flexible(), alignment: .top), count: Int(UIScreen.main.bounds.size.width) / 125)
    }

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
        DetectBottomScrollView {
            VStack {
                LazyVGrid(columns: tracks) {
                    ForEach(viewModel.items, id: \.id) { item in
                        PortraitPosterButton(item: item) { item in
                            libraryRouter.route(to: \.item, item)
                        }
                    }
                }
                .ignoresSafeArea()
                .listRowSeparator(.hidden)
                .onRotate { _ in
                    recalcTracks()
                }

                Spacer()
                    .frame(height: 30)
            }
        } didReachBottom: { newValue in
            if newValue && viewModel.hasNextPage {
                viewModel.requestNextPageAsync()
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

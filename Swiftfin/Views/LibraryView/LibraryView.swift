//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import SwiftUI

struct LibraryView: View {

    @EnvironmentObject
    private var router: LibraryCoordinator.Router
    @ObservedObject
    var viewModel: LibraryViewModel

    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType
    @Default(.Customization.Library.viewType)
    private var libraryViewType

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }

    private var gridLayout: NSCollectionLayoutSection.GridLayoutMode {
        if libraryGridPosterType == .landscape && UIDevice.isPhone {
            return .fixedNumberOfColumns(2)
        } else {
            return .adaptive(withMinItemSize: libraryGridPosterType.width + (UIDevice.isIPad ? 10 : 0))
        }
    }

    @ViewBuilder
    private var libraryListView: some View {
        CollectionView(items: viewModel.items) { _, item, _ in
            LibraryItemRow(item: item)
                .padding()
        }
        .layout { _, layoutEnvironment in
            .list(using: .init(appearance: .plain), layoutEnvironment: layoutEnvironment)
        }
        .willReachEdge(insets: .init(top: 0, leading: 0, bottom: 200, trailing: 0)) { edge in
            if !viewModel.isLoading && edge == .bottom {
                viewModel.requestNextPageAsync()
            }
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
        .ignoresSafeArea()
    }

    @ViewBuilder
    private var libraryGridView: some View {
        CollectionView(items: viewModel.items) { _, item, _ in
            PosterButton(item: item, type: libraryGridPosterType)
                .scaleItem(libraryGridPosterType == .landscape && UIDevice.isPhone ? 0.85 : 1)
                .onSelect { item in
                    router.route(to: \.item, item)
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: gridLayout,
                sectionInsets: .init(top: 0, leading: 10, bottom: 0, trailing: 10)
            )
        }
        .willReachEdge(insets: .init(top: 0, leading: 0, bottom: 200, trailing: 0)) { edge in
            if !viewModel.isLoading && edge == .bottom {
                viewModel.requestNextPageAsync()
            }
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
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
                switch libraryViewType {
                case .grid:
                    libraryGridView
                case .list:
                    libraryListView
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                Button {
                    switch libraryViewType {
                    case .grid:
                        libraryViewType = .list
                    case .list:
                        libraryViewType = .grid
                    }
                } label: {
                    switch libraryViewType {
                    case .grid:
                        Image(systemName: "list.dash")
                    case .list:
                        Image(systemName: "square.grid.2x2")
                    }
                }

                Button {
                    router
                        .route(to: \.filter, (
                            filters: $viewModel.filters,
                            enabledFilterType: viewModel.enabledFilterType,
                            parentId: viewModel.library?.id ?? ""
                        ))
                } label: {
                    Image(systemName: "line.horizontal.3.decrease.circle")
                }
                .foregroundColor(viewModel.filters == .default ? .accentColor : Color(UIColor.systemOrange))
            }
        }
    }
}

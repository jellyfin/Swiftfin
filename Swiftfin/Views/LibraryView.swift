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
    private var libraryRouter: LibraryCoordinator.Router
    @ObservedObject
    var viewModel: LibraryViewModel

    @Default(.Customization.libraryPosterType)
    private var libraryPosterType

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
    }

    private var gridLayout: NSCollectionLayoutSection.GridLayoutMode {
        if libraryPosterType == .landscape && UIDevice.isPhone {
            return .fixedNumberOfColumns(2)
        } else {
            return .adaptive(withMinItemSize: libraryPosterType.width + (UIDevice.isIPad ? 10 : 0))
        }
    }

    @ViewBuilder
    private var libraryItemsView: some View {
        CollectionView(items: viewModel.items) { _, item, _ in
            PosterButton(item: item, type: libraryPosterType)
                .onSelect { item in
                    libraryRouter.route(to: \.item, item)
                }
                .scaleItem(libraryPosterType == .landscape && UIDevice.isPhone ? 0.8 : 1)
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: gridLayout
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
                .foregroundColor(viewModel.filters == .default ? .accentColor : Color(UIColor.systemOrange))
            }
        }
    }
}

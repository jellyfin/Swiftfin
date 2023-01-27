//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

struct PagingLibraryView: View {

    @ObservedObject
    var viewModel: PagingLibraryViewModel
    private var onSelect: (BaseItemDto) -> Void

    @Default(.Customization.Library.gridPosterType)
    private var libraryGridPosterType
    @Default(.Customization.Library.viewType)
    private var libraryViewType

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
                .onSelect {
                    onSelect(item)
                }
                .padding()
        }
        .layout { _, layoutEnvironment in
            .list(using: .init(appearance: .plain), layoutEnvironment: layoutEnvironment)
        }
        .willReachEdge(insets: .init(top: 0, leading: 0, bottom: 200, trailing: 0)) { edge in
            if !viewModel.isLoading && edge == .bottom {
                viewModel.requestNextPage()
            }
        }
        .onEdgeReached { edge in
            if viewModel.hasNextPage, !viewModel.isLoading, edge == .bottom {
                viewModel.requestNextPage()
            }
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
    }

    @ViewBuilder
    private var libraryGridView: some View {
        CollectionView(items: viewModel.items) { _, item, _ in
            PosterButton(item: item, type: libraryGridPosterType)
                .scaleItem(libraryGridPosterType == .landscape && UIDevice.isPhone ? 0.85 : 1)
                .onSelect {
                    onSelect(item)
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
                viewModel.requestNextPage()
            }
        }
        .onEdgeReached { edge in
            if viewModel.hasNextPage, !viewModel.isLoading, edge == .bottom {
                viewModel.requestNextPage()
            }
        }
        .configure { configuration in
            configuration.showsVerticalScrollIndicator = false
        }
    }

    var body: some View {
        switch libraryViewType {
        case .grid:
            libraryGridView
        case .list:
            libraryListView
        }
    }
}

extension PagingLibraryView {
    init(viewModel: PagingLibraryViewModel) {
        self.viewModel = viewModel
        self.onSelect = { _ in }
    }

    func onSelect(_ action: @escaping (BaseItemDto) -> Void) -> Self {
        var copy = self
        copy.onSelect = action
        return copy
    }
}

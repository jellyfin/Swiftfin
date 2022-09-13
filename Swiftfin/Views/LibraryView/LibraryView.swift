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

    private func baseItemOnSelect(_ item: BaseItemDto) {
        if let baseParent = viewModel.parent as? BaseItemDto {
            if baseParent.collectionType == "folders" {
                router.route(to: \.library, .init(parent: item, type: .folders, filters: .init()))
            } else if item.type == .folder {
                router.route(to: \.library, .init(parent: item, type: .library, filters: .init()))
            } else {
                router.route(to: \.item, item)
            }
        } else {
            router.route(to: \.item, item)
        }
    }

    @ViewBuilder
    private var libraryListView: some View {
        CollectionView(items: viewModel.items) { _, item, _ in
            LibraryItemRow(item: item)
                .onSelect {
                    baseItemOnSelect(item)
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
                .onSelect {
                    baseItemOnSelect(item)
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
        .navigationTitle(viewModel.parent?.displayName ?? "")
        .navigationBarTitleDisplayMode(.inline)
        .navBarDrawer {
            ScrollView(.horizontal, showsIndicators: false) {
                FilterDrawerHStack(viewModel: viewModel.filterViewModel)
                    .onSelect { filterCoordinatorParameters in
                        router.route(to: \.filter, filterCoordinatorParameters)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 1)
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {

                if viewModel.isLoading && !viewModel.items.isEmpty {
                    ProgressView()
                }

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
            }
        }
    }
}

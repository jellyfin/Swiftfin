//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
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

    @ObservedObject
    var viewModel: LibraryViewModel

    @ViewBuilder
    private var loadingView: some View {
        ProgressView()
    }

    @ViewBuilder
    private var noResultsView: some View {
        L10n.noResults.text
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
    private var libraryItemsView: some View {
        PagingLibraryView(viewModel: viewModel)
            .onSelect { item in
                baseItemOnSelect(item)
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
                        .onSelect { response in
                            if let item = response.items?.first {
                                router.route(to: \.item, item)
                            }
                        }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
    }
}

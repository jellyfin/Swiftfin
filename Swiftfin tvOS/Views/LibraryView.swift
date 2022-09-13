//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import Introspect
import JellyfinAPI
import SwiftUI

struct LibraryView: View {

    @EnvironmentObject
    private var router: LibraryCoordinator.Router
    @ObservedObject
    var viewModel: LibraryViewModel
    @State
    private var scrollViewOffset: CGPoint = .zero

    @Default(.Customization.Library.gridPosterType)
    private var libraryPosterType

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
        CollectionView(items: viewModel.items) { _, item, _ in
            PosterButton(item: item, type: libraryPosterType)
                .onSelect { item in
                    baseItemOnSelect(item)
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: .fixedNumberOfColumns(7),
                lineSpacing: 50
            )
        }
        .willReachEdge(insets: .init(top: 0, leading: 0, bottom: 600, trailing: 0)) { edge in
            if !viewModel.isLoading && edge == .bottom {
                viewModel.requestNextPage()
            }
        }
        .scrollViewOffset($scrollViewOffset)
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
    }
}

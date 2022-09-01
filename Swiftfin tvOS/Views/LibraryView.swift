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
import SwiftUI

struct LibraryView: View {

    @EnvironmentObject
    private var libraryRouter: LibraryCoordinator.Router
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

    @ViewBuilder
    private var libraryItemsView: some View {
        CollectionView(items: viewModel.items) { _, item, _ in
            PosterButton(item: item, type: libraryPosterType)
                .onSelect { item in
                    libraryRouter.route(to: \.item, item)
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: .fixedNumberOfColumns(6),
                lineSpacing: 50
            )
        }
        .willReachEdge(insets: .init(top: 0, leading: 0, bottom: 600, trailing: 0)) { edge in
            if !viewModel.isLoading && edge == .bottom {
                viewModel.requestNextPageAsync()
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

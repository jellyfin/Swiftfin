//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Introspect
import SwiftUI

struct LibraryView: View {

    @EnvironmentObject
    private var libraryRouter: LibraryCoordinator.Router
    @StateObject
    var viewModel: LibraryViewModel

    @State
    private var introspectScrollView: UIScrollView?

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
                .content { _ in
                    EmptyView()
                }
        }
        .layout { _, layoutEnvironment in
            .grid(
                layoutEnvironment: layoutEnvironment,
                layoutMode: .fixedNumberOfColumns(6),
                lineSpacing: 50
            )
        }
        .introspectScrollView { uiScrollView in
            // TODO: Figure out hiding the tabbar
            self.introspectScrollView = uiScrollView
        }
        .introspectTabBarController { tabBarController in
            tabBarController.setContentScrollView(introspectScrollView, for: .top)
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
    }
}

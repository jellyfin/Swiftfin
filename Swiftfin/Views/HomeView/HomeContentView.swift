//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension HomeView {

    struct ContentView: View {

        @EnvironmentObject
        private var homeRouter: HomeCoordinator.Router
        @ObservedObject
        var viewModel: HomeViewModel

        var body: some View {
            RefreshableScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.resumeItems.isEmpty {
                        ContinueWatchingView(viewModel: viewModel)
                    }

                    if !viewModel.nextUpItems.isEmpty {
                        PortraitPosterHStack(
                            title: L10n.nextUp,
                            items: viewModel.nextUpItems,
                            itemWidth: UIDevice.isIPad ? 130 : 110
                        ) { item in
                            homeRouter.route(to: \.item, item)
                        }
                    }

                    if !viewModel.latestAddedItems.isEmpty {
                        PortraitPosterHStack(
                            title: L10n.recentlyAdded,
                            items: viewModel.latestAddedItems,
                            itemWidth: UIDevice.isIPad ? 130 : 110
                        ) { item in
                            homeRouter.route(to: \.item, item)
                        }
                    }

                    ForEach(viewModel.libraries, id: \.self) { library in
                        LatestInLibraryView(viewModel: .init(library: library))
                    }
                }
                .padding(.bottom, 50)
            } onRefresh: {
                viewModel.refresh()
            }
        }
    }
}

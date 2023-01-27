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

extension HomeView {

    struct ContentView: View {

        @EnvironmentObject
        private var homeRouter: HomeCoordinator.Router
        @ObservedObject
        var viewModel: HomeViewModel

        @Default(.Customization.nextUpPosterType)
        var nextUpPosterType
        @Default(.Customization.recentlyAddedPosterType)
        var recentlyAddedPosterType

        var body: some View {
            RefreshableScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if !viewModel.resumeItems.isEmpty {
                        ContinueWatchingView(viewModel: viewModel)
                    }

                    if viewModel.hasNextUp {
                        NextUpView(viewModel: .init())
                    }

                    if viewModel.hasRecentlyAdded {
                        RecentlyAddedView(
                            viewModel: .init(
                                itemTypes: [.movie, .series],
                                filters: .init(sortOrder: [APISortOrder.descending.filter], sortBy: [SortBy.dateAdded.filter])
                            )
                        )
                    }

                    ForEach(viewModel.libraries, id: \.self) { library in
                        LatestInLibraryView(viewModel: .init(parent: library, type: .library, filters: .recent))
                    }
                }
                .padding(.bottom, 50)
            } onRefresh: {
                viewModel.refresh()
            }
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionView
import Defaults
import JellyfinAPI
import SwiftUI

extension HomeView {

    struct ContentView: View {

        @Default(.Customization.nextUpPosterType)
        private var nextUpPosterType
        @Default(.Customization.recentlyAddedPosterType)
        private var recentlyAddedPosterType

        @ObservedObject
        var viewModel: HomeViewModel

        var body: some View {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {

                    if viewModel.resumeItems.isNotEmpty {
                        ContinueWatchingView(viewModel: viewModel)
                    }

                    if viewModel.nextUpViewModel.items.isNotEmpty {
                        NextUpView(viewModel: viewModel.nextUpViewModel)
                    }

                    if viewModel.recentlyAddedViewModel.items.isNotEmpty {
                        RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                    }

                    ForEach(viewModel.libraries) { viewModel in
                        LatestInLibraryView(viewModel: viewModel)
                    }
                }
                .padding(.bottom, 50)
            }
            .refreshable {
                await viewModel.refresh()
            }
        }
    }
}

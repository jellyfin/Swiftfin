//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension HomeView {

    struct ContentView: View {

        @EnvironmentObject
        private var router: HomeCoordinator.Router
        @ObservedObject
        var viewModel: HomeViewModel

        var body: some View {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {

                    if viewModel.resumeItems.isEmpty {
                        CinematicRecentlyAddedView(viewModel: .init(
                            itemTypes: [.movie, .series],
                            filters: .init(sortOrder: [APISortOrder.descending.filter], sortBy: [SortBy.dateAdded.filter])
                        ))

                        if viewModel.hasNextUp {
                            NextUpView(viewModel: .init())
                        }
                    } else {
                        CinematicResumeView(viewModel: viewModel)

                        if viewModel.hasNextUp {
                            NextUpView(viewModel: .init())
                        }

                        if viewModel.hasRecentlyAdded {
                            RecentlyAddedView(viewModel: .init(
                                itemTypes: [.movie, .series],
                                filters: .init(sortOrder: [APISortOrder.descending.filter], sortBy: [SortBy.dateAdded.filter])
                            ))
                        }
                    }

                    ForEach(viewModel.libraries, id: \.self) { library in
                        LatestInLibraryView(viewModel: .init(parent: library, type: .library, filters: .recent))
                    }
                }
            }
        }
    }
}

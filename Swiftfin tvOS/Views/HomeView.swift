//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import Introspect
import JellyfinAPI
import SwiftUI

struct HomeView: View {

    @EnvironmentObject
    private var router: HomeCoordinator.Router
    @ObservedObject
    var viewModel: HomeViewModel

    var body: some View {
        if viewModel.isLoading {
            ProgressView()
        } else {
            ScrollView {
                LazyVStack(alignment: .leading) {
                    if viewModel.resumeItems.isEmpty {
                        CinematicItemSelector(items: viewModel.nextUpItems)
                            .onSelect { item in
                                router.route(to: \.item, item)
                            }
                    } else {
                        CinematicItemSelector(items: viewModel.resumeItems)
                            .imageOverlay { item in
                                LandscapePosterProgressBar(
                                    title: item.progress ?? L10n.continue,
                                    progress: (item.userData?.playedPercentage ?? 0) / 100
                                )
                            }
                            .onSelect { item in
                                router.route(to: \.item, item)
                            }
                    }
                    
                    if !viewModel.latestAddedItems.isEmpty {
                        PosterHStack(title: L10n.recentlyAdded, type: .portrait, items: viewModel.latestAddedItems)
                            .onSelect { item in
                                router.route(to: \.item, item)
                            }
                    }

                    ForEach(viewModel.libraries, id: \.self) { library in
                        LatestInLibraryView(viewModel: LatestMediaViewModel(library: library))
                    }
                }
            }
            .edgesIgnoringSafeArea(.top)
            .edgesIgnoringSafeArea(.horizontal)
        }
    }
}

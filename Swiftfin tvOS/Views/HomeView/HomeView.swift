//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

struct HomeView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = HomeViewModel()

    @Default(.Customization.Home.showRecentlyAdded)
    private var showRecentlyAdded

    @ViewBuilder
    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                if viewModel.resumeItems.isNotEmpty {
                    CinematicResumeView(viewModel: viewModel)

                    NextUpView(viewModel: viewModel.nextUpViewModel)

                    if showRecentlyAdded {
                        RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                    }
                } else {
                    if showRecentlyAdded {
                        CinematicRecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                    }

                    NextUpView(viewModel: viewModel.nextUpViewModel)
                        .safeAreaPadding(.top, 150)
                }

                ForEach(viewModel.libraries) { viewModel in
                    LatestInLibraryView(viewModel: viewModel)
                }
            }
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .content:
                contentView
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .refreshable {
            viewModel.send(.refresh)
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .ignoresSafeArea()
        .sinceLastDisappear { interval in
            if interval > 60 || viewModel.notificationsReceived.contains(.itemMetadataDidChange) {
                viewModel.send(.backgroundRefresh)
                viewModel.notificationsReceived.remove(.itemMetadataDidChange)
            }
        }
    }
}

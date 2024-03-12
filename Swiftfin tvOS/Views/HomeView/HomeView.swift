//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import Introspect
import JellyfinAPI
import SwiftUI

struct HomeView: View {

    @EnvironmentObject
    private var router: HomeCoordinator.Router

    @StateObject
    private var viewModel = HomeViewModel()

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                if viewModel.resumeItems.isNotEmpty {
                    CinematicResumeView(viewModel: viewModel)

                    NextUpView(viewModel: viewModel.nextUpViewModel)

                    RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)
                } else {
                    CinematicRecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)

                    NextUpView(viewModel: viewModel.nextUpViewModel)
                }

                ForEach(viewModel.libraries) { viewModel in
                    LatestInLibraryView(viewModel: viewModel)
                }
            }
        }
    }

    var body: some View {
        WrappedView {
            Group {
                switch viewModel.state {
                case .content:
                    contentView
                case let .error(error):
                    Text(error.localizedDescription)
                case .initial, .refreshing:
                    ProgressView()
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.2)))
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .ignoresSafeArea()
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import Foundation
import SwiftUI

// TODO: seems to redraw view when popped to sometimes?
//       - similar to MediaView TODO bug?
struct HomeView: View {

    @Default(.Customization.nextUpPosterType)
    private var nextUpPosterType
    @Default(.Customization.recentlyAddedPosterType)
    private var recentlyAddedPosterType

    @EnvironmentObject
    private var router: HomeCoordinator.Router

    @StateObject
    private var viewModel = HomeViewModel()

    private var contentView: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {

                ContinueWatchingView(viewModel: viewModel)

                NextUpView(viewModel: viewModel.nextUpViewModel)

                RecentlyAddedView(viewModel: viewModel.recentlyAddedViewModel)

                ForEach(viewModel.libraries) { viewModel in
                    LatestInLibraryView(viewModel: viewModel)
                }
            }
            .edgePadding(.vertical)
        }
    }

    private func errorView(with error: some Error) -> some View {
        ErrorView(error: error)
            .onRetry {
                viewModel.send(.refresh)
            }
    }

    var body: some View {
        WrappedView {
            Group {
                switch viewModel.state {
                case .content:
                    contentView
                case let .error(error):
                    errorView(with: error)
                case .initial, .refreshing:
                    ProgressView()
                }
            }
            .transition(.opacity.animation(.linear(duration: 0.1)))
        }
        .onFirstAppear {
            viewModel.send(.refresh)
        }
        .navigationTitle(L10n.home)
        .toolbar {
            ToolbarItemGroup(placement: .topBarTrailing) {
                Button {
                    router.route(to: \.settings)
                } label: {
                    Image(systemName: "gearshape.fill")
                        .accessibilityLabel(L10n.settings)
                }
            }
        }
    }
}

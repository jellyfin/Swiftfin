//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

// TODO: wide + narrow view toggling
//       - after `PosterType` has been refactored and with customizable toggle button
// TODO: sorting by number/filtering
//       - should be able to use normal filter view model, but how to add custom filters for data context?

struct ChannelLibraryView: View {

    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router

    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var viewModel = ChannelLibraryViewModel()

    init() {
        if UIDevice.isPhone {
            layout = .columns(1)
        } else {
            layout = .minWidth(250)
        }
    }

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.elements,
            layout: layout
        ) { channel in
            WideChannelGridItem(channel: channel)
                .onSelect {
                    guard let mediaSource = channel.channel.mediaSources?.first else { return }
                    mainRouter.route(
                        to: \.liveVideoPlayer,
                        LiveVideoPlayerManager(item: channel.channel, mediaSource: mediaSource)
                    )
                }
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.send(.getNextPage)
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
            switch viewModel.state {
            case .content:
                if viewModel.elements.isEmpty {
                    L10n.noResults.text
                } else {
                    contentView
                }
            case let .error(error):
                errorView(with: error)
            case .initial, .refreshing:
                DelayedProgressView()
            }
        }
        .navigationTitle(L10n.channels)
        .navigationBarTitleDisplayMode(.inline)
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.send(.refresh)
            }
        }
        .afterLastDisappear { interval in
            // refresh after 3 hours
            if interval >= 10800 {
                viewModel.send(.refresh)
            }
        }
        .topBarTrailing {

            if viewModel.backgroundStates.contains(.gettingNextPage) {
                ProgressView()
            }
        }
    }
}

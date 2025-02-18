//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Foundation
import JellyfinAPI
import SwiftUI

struct ChannelLibraryView: View {

    @EnvironmentObject
    private var router: VideoPlayerWrapperCoordinator.Router

    @StateObject
    private var viewModel = ChannelLibraryViewModel()

    @ViewBuilder
    private var contentView: some View {
        CollectionVGrid(
            uniqueElements: viewModel.elements,
            layout: .columns(3, insets: .init(0), itemSpacing: 25, lineSpacing: 25)
        ) { channel in
            WideChannelGridItem(channel: channel)
                .onSelect {
                    guard let mediaSource = channel.channel.mediaSources?.first else { return }
                    router.route(
                        to: \.liveVideoPlayer,
                        LiveVideoPlayerManager(item: channel.channel, mediaSource: mediaSource)
                    )
                }
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.send(.getNextPage)
        }
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                if viewModel.elements.isEmpty {
                    L10n.noResults.text
                } else {
                    contentView
                }
            case let .error(error):
                ErrorView(error: error)
                    .onRetry {
                        viewModel.send(.refresh)
                    }
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
        .ignoresSafeArea()
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.send(.refresh)
            }
        }
        .sinceLastDisappear { interval in
            // refresh after 3 hours
            if interval >= 10800 {
                viewModel.send(.refresh)
            }
        }
    }
}

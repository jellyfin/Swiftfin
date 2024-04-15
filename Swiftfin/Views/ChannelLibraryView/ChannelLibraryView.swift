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

struct ChannelsView: View {

    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var viewModel = ChannelsViewModel()

    init() {
        if UIDevice.isPhone {
            layout = .columns(1)
        } else {
            layout = .minWidth(250)
        }
    }

    // MARK: item view

    private static func gridView(channel: ChannelProgram) -> some View {
        ChannelGridItem(channel: channel)
    }

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.elements,
            layout: layout
        ) { item in
            ChannelGridItem(channel: item)
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
    }
}

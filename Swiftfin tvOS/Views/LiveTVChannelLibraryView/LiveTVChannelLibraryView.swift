//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Foundation
import JellyfinAPI
import SwiftUI

struct LiveTVChannelLibraryView: View {

    @StateObject
    private var viewModel = LiveTVChannelLibraryViewModel()

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.elements,
            layout: .columns(2, insets: .init(30), itemSpacing: 30, lineSpacing: 30)
        ) { channel in
            WideChannelGridItem(channel: channel)
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.send(.getNextPage)
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            WrappedView {
                switch viewModel.state {
                case .content:
                    if viewModel.elements.isEmpty {
                        L10n.noResults.text
                    } else {
                        contentView
                    }
                case let .error(error):
                    Text(error.localizedDescription)
                case .initial, .refreshing:
                    ProgressView()
                }
            }
        }
        .ignoresSafeArea()
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
    }
}

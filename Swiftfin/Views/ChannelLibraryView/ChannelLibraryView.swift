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
// TODO: saving item display type
//       - wait until after user refactor

struct ChannelLibraryView: View {

    @EnvironmentObject
    private var mainRouter: MainCoordinator.Router

    @State
    private var itemDisplayType: ItemDisplayType = .wide
    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var viewModel = ChannelLibraryViewModel()

    // MARK: init

    init() {
        if UIDevice.isPhone {
            layout = Self.padlayout(itemDisplayType: .wide)
        } else {
            layout = Self.phonelayout(itemDisplayType: .wide)
        }
    }

    // MARK: layout

    private static func padlayout(
        itemDisplayType: ItemDisplayType
    ) -> CollectionVGridLayout {
        switch itemDisplayType {
        case .narrow, .square:
            .minWidth(150)
        case .wide:
            .minWidth(250)
        }
    }

    private static func phonelayout(
        itemDisplayType: ItemDisplayType
    ) -> CollectionVGridLayout {
        switch itemDisplayType {
        case .narrow, .square:
            .columns(3)
        case .wide:
            .columns(1)
        }
    }

    // MARK: item view

    private func narrowChannelView(channel: ChannelProgram) -> some View {
        PosterButton(item: channel.channel, type: .square)
            .onSelect {
                guard let mediaSource = channel.channel.mediaSources?.first else { return }
                mainRouter.route(
                    to: \.liveVideoPlayer,
                    LiveVideoPlayerManager(item: channel.channel, mediaSource: mediaSource)
                )
            }
    }

    private func wideChannelView(channel: ChannelProgram) -> some View {
        WideChannelView(channel: channel)
            .onSelect {
                guard let mediaSource = channel.channel.mediaSources?.first else { return }
                mainRouter.route(
                    to: \.liveVideoPlayer,
                    LiveVideoPlayerManager(item: channel.channel, mediaSource: mediaSource)
                )
            }
    }

    private var contentView: some View {
        CollectionVGrid(
            $viewModel.elements,
            layout: $layout
        ) { channel in
            switch itemDisplayType {
            case .narrow, .square:
                narrowChannelView(channel: channel)
            case .wide:
                wideChannelView(channel: channel)
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
        .onChange(of: itemDisplayType) { newValue in
            if UIDevice.isPhone {
                layout = Self.phonelayout(itemDisplayType: newValue)
            } else {
                layout = Self.padlayout(itemDisplayType: newValue)
            }
        }
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
        .topBarTrailing {

            if viewModel.backgroundStates.contains(.gettingNextPage) {
                ProgressView()
            }

            Menu {
                Button {
                    itemDisplayType = .narrow
                } label: {
                    if itemDisplayType == .narrow {
                        Label("Narrow", systemImage: "checkmark")
                    } else {
                        Label("Narrow", systemImage: "square.grid.2x2.fill")
                    }
                }

                Button {
                    itemDisplayType = .wide
                } label: {
                    if itemDisplayType == .wide {
                        Label("Wide", systemImage: "checkmark")
                    } else {
                        Label("Wide", systemImage: "square.fill.text.grid.1x2")
                    }
                }
            } label: {
                if itemDisplayType == .narrow {
                    Label("Narrow", systemImage: "square.grid.2x2.fill")
                } else {
                    Label("Wide", systemImage: "square.fill.text.grid.1x2")
                }
            }
        }
    }
}

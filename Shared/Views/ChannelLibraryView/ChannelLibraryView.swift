//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import Foundation
import JellyfinAPI
import SwiftUI

// TODO: sorting by number/filtering
//       - see if can use normal filter view model?
//       - how to add custom filters for data context?
// TODO: saving item display type/detailed column count
//       - wait until after user refactor

struct ChannelLibraryView: View {

    @Router
    private var router

    @State
    private var channelDisplayType: LibraryDisplayType = .list
    @State
    private var layout: CollectionVGridLayout

    @StateObject
    private var viewModel = PagingLibraryViewModel(
        library: ChannelProgramLibrary()
    )

    // MARK: init

    init() {
        if UIDevice.isPhone {
            layout = Self.phonelayout(channelDisplayType: .list)
        } else {
            layout = Self.padlayout(channelDisplayType: .list)
        }
    }

    // MARK: layout

    private static func padlayout(
        channelDisplayType: LibraryDisplayType
    ) -> CollectionVGridLayout {
        switch channelDisplayType {
        case .grid:
            .minWidth(150)
        case .list:
            .minWidth(250)
        }
    }

    private static func phonelayout(
        channelDisplayType: LibraryDisplayType
    ) -> CollectionVGridLayout {
        switch channelDisplayType {
        case .grid:
            .columns(3)
        case .list:
            .columns(1)
        }
    }

    // MARK: item view

    private func compactChannelView(channel: ChannelProgram) -> some View {
        CompactChannelView(channel: channel.channel) {
            router.route(
                to: .videoPlayer(
                    provider: channel.channel.getPlaybackItemProvider(
                        userSession: viewModel.userSession
                    )
                )
            )
        }
    }

    private func detailedChannelView(channel: ChannelProgram) -> some View {
        DetailedChannelView(channel: channel) {
            router.route(
                to: .videoPlayer(
                    provider: channel.channel.getPlaybackItemProvider(
                        userSession: viewModel.userSession
                    )
                )
            )
        }
    }

    @ViewBuilder
    private var contentView: some View {
        CollectionVGrid(
            uniqueElements: viewModel.elements,
            layout: layout
        ) { channel in
            switch channelDisplayType {
            case .grid:
                compactChannelView(channel: channel)
            case .list:
                detailedChannelView(channel: channel)
            }
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.retrieveNextPage()
        }
    }

    var body: some View {
        ZStack {
            Color.clear

            switch viewModel.state {
            case .content:
                if viewModel.elements.isEmpty {
                    Text(L10n.noResults)
                } else {
                    contentView
                }
            case .error:
                viewModel.error.map(ErrorView.init)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .navigationTitle(L10n.channels)
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            try? await viewModel.refresh()
        }
        .onChange(of: channelDisplayType) { newValue in
            if UIDevice.isPhone {
                layout = Self.phonelayout(channelDisplayType: newValue)
            } else {
                layout = Self.padlayout(channelDisplayType: newValue)
            }
        }
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.refresh()
            }
        }
        .sinceLastDisappear { interval in
            // refresh after 3 hours
            if interval >= 10800 {
                viewModel.refresh()
            }
        }
        .topBarTrailing {

            if viewModel.background.is(.retrievingNextPage) {
                ProgressView()
            }

            Menu {
                // We repurposed `LibraryDisplayType` but want different labels
                Picker(L10n.channelDisplay, selection: $channelDisplayType) {

                    Label(L10n.compact, systemImage: LibraryDisplayType.grid.systemImage)
                        .tag(LibraryDisplayType.grid)

                    Label(L10n.detailed, systemImage: LibraryDisplayType.list.systemImage)
                        .tag(LibraryDisplayType.list)
                }
            } label: {
                Label(
                    channelDisplayType.displayTitle,
                    systemImage: channelDisplayType.systemImage
                )
            }
        }
    }
}

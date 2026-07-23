//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LiveTVGuideSupplement: MediaPlayerSupplement {

    let displayTitle: String = L10n.guide

    var id: String {
        "LiveTVGuide"
    }

    var videoPlayerBody: some PlatformView {
        GuideOverlay()
    }
}

extension LiveTVGuideSupplement {

    private struct GuideOverlay: PlatformView {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @StateObject
        private var channelsViewModel = PagingLibraryViewModel(library: GuideChannelsLibrary())
        @StateObject
        private var viewModel = GuideViewModel(hours: 12, lookback: 0)

        private func select(channel: BaseItemDto) {
            defer { containerState.select(supplement: nil) }

            guard channel.id != manager.item.id,
                  let provider = channel.getPlaybackItemProvider(userSession: viewModel.userSession)
            else { return }

            manager.playNewItem(provider: provider)
        }

        private func select(program: BaseItemDto) {
            defer { containerState.select(supplement: nil) }

            guard program.channelID != manager.item.id,
                  let provider = program.getPlaybackItemProvider(userSession: viewModel.userSession)
            else { return }

            manager.playNewItem(provider: provider)
        }

        private var content: some View {
            ZStack {
                switch (channelsViewModel.state, viewModel.state) {
                case (.initial, _), (.refreshing, _), (_, .initial), (_, .refreshing):
                    ProgressView()
                case (.error, _):
                    channelsViewModel.error.map(ErrorView.init)
                case (_, .error):
                    viewModel.error.map(ErrorView.init)
                case (.content, _):
                    if channelsViewModel.displayedElements.isEmpty {
                        ContentUnavailableView(L10n.noPrograms.localizedCapitalized, systemImage: "tv")
                    } else {
                        LiveTVGuideContentView(
                            viewModel: viewModel,
                            channels: Array(channelsViewModel.displayedElements),
                            selectedChannelID: manager.item.id,
                            playsOnSelect: true,
                            onReachedBottomEdge: { channelsViewModel.getNextPage() },
                            onSelectChannel: select(channel:),
                            onSelectProgram: select(program:)
                        )
                    }
                }
            }
            .onFirstAppear {
                if channelsViewModel.state == .initial {
                    channelsViewModel.refresh()
                }
            }
            .backport
            .onChange(of: Array(channelsViewModel.displayedElements)) { _, channels in
                guard viewModel.state == .initial else { return }
                viewModel.refresh(channels: channels)
            }
        }

        var iOSView: some View {
            content
        }

        var tvOSView: some View {
            content
                .focusSection()
        }
    }
}

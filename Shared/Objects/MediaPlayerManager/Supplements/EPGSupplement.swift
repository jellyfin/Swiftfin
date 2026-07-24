//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EPGSupplement: MediaPlayerSupplement {

    let displayTitle: String = L10n.guide

    var id: String {
        "EPG"
    }

    var videoPlayerBody: some PlatformView {
        GuideOverlay()
    }
}

extension EPGSupplement {

    private struct GuideOverlay: PlatformView {

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @StateObject
        private var channelsViewModel = PagingLibraryViewModel(library: EPGChannelsLibrary())
        @StateObject
        private var viewModel = EPGViewModel()

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
                        EPGContentView(
                            viewModel: viewModel,
                            channelsViewModel: channelsViewModel,
                            playing: manager.item.id
                        ) { item in
                            if item.id == manager.item.id || item.channelID == manager.item.id {
                                containerState.select(supplement: nil)
                                return
                            }

                            guard let provider = item.getPlaybackItemProvider(userSession: viewModel.userSession) else {
                                return
                            }

                            containerState.select(supplement: nil)
                            manager.playNewItem(provider: provider)
                        }
                    }
                }
            }
            .onFirstAppear {
                if channelsViewModel.state == .initial {
                    channelsViewModel.refresh()
                }
            }
            .backport
            .onChange(of: channelsViewModel.displayedElements) { _, channels in
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

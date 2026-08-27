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
    let id: String = "EPG"
    let presentationStyle: MediaPlayerSupplementPresentationStyle = .expanded

    var videoPlayerBody: some PlatformView {
        GuideOverlay()
    }
}

extension EPGSupplement {

    private struct GuideOverlay: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var lastSuccessfulRefresh = Date.distantPast

        @StateObject
        private var viewModel = EPGViewModel()

        private let refreshInterval: TimeInterval = 3 * 60

        @ViewBuilder
        private var content: some View {
            EPGLoadableView(viewModel: viewModel) {
                EPGContentView(
                    viewModel: viewModel,
                    selectedChannelID: manager.item.id,
                    action: select
                )
            }
            .padding(.leading, safeAreaInsets.leading)
            .padding(.trailing, safeAreaInsets.trailing)
            .padding(.bottom, safeAreaInsets.bottom)
            .onFirstAppear {
                viewModel.refresh(startDate: nil)
            }
            .onChange(of: viewModel.state) { _, state in
                guard state == .content else { return }
                lastSuccessfulRefresh = .now
            }
            .onChange(of: containerState.selectedSupplement?.id) { _, id in
                guard id == "EPG",
                      viewModel.state != .initial,
                      viewModel.state != .refreshing,
                      !viewModel.background.is(.gettingNextPage)
                else { return }

                let hasRecentGuide = Date.now.timeIntervalSince(lastSuccessfulRefresh) < refreshInterval
                let hasError = viewModel.state == .error

                guard hasError || !hasRecentGuide else { return }

                Task {
                    await viewModel.refresh(startDate: nil)
                }
            }
            .refreshable {
                await viewModel.refresh(startDate: nil)
            }
            .focusSection()
        }

        var iOSView: some View {
            content
        }

        var tvOSView: some View {
            content
                .focusSection()
        }

        private func select(_ item: BaseItemDto) {
            let playbackItem = item.channelID
                .flatMap { channelID in
                    viewModel.channels.first { $0.id == channelID }
                } ?? item

            if playbackItem.id == manager.item.id {
                containerState.select(supplement: nil)
                return
            }

            guard let provider = playbackItem.getPlaybackItemProvider(userSession: viewModel.userSession) else {
                return
            }

            containerState.select(supplement: nil)
            manager.playNewItem(provider: provider)
        }
    }
}

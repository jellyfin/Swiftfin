//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

@MainActor
struct EPGSupplement {

    let displayTitle: String = L10n.guide
    let id: String = "EPG"
    let presentationStyle: VideoPlayerSupplementPresentationStyle = .expanded
}

extension EPGSupplement: VideoPlayerSupplement {

    var body: some View {
        GuideOverlay()
    }

    private struct GuideOverlay: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        @State
        private var lastSuccessfulRefresh = Date.distantPast

        @StateObject
        private var viewModel = EPGViewModel()

        private let refreshInterval: TimeInterval = 3 * 60

        private var content: some View {
            EPGLoadableView(viewModel: viewModel) {
                EPGContentView(
                    viewModel: viewModel,
                    selectedChannelID: mediaSession.item.id,
                    action: select
                )
            }
            .onFirstAppear {
                viewModel.refresh(startDate: nil)
            }
            .onChange(of: viewModel.state) { _, state in
                guard state == .content else { return }

                lastSuccessfulRefresh = .now
            }
            .onChange(of: viewState.selectedSupplementID) { _, id in
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
                .padding(.leading, safeAreaInsets.leading)
                .padding(.trailing, safeAreaInsets.trailing)
        }

        var tvOSView: some View {
            content
                .focusSection()
        }

        private func select(_ item: BaseItemDto) {
            let playbackItem = item.channelID
                .flatMap { channelID in
                    viewModel.channels.first { $0.itemID == channelID }?.value
                } ?? item

            if playbackItem.id == mediaSession.item.id {
                viewState.selectedSupplementID = nil
                return
            }

            guard let intent = playbackItem.getPlaybackIntent(userSession: viewModel.userSession) else {
                return
            }

            viewState.selectedSupplementID = nil
            mediaSession.playNewItem(intent: intent)
        }
    }
}

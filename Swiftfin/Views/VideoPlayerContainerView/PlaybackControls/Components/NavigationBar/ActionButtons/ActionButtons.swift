//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar {

    struct ActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var barActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var menuActionButtons

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ViewBuilder
        private func view(for button: VideoPlayerActionButton) -> some View {
            switch button {
            case .aspectFill:
                AspectFill()
            case .audio:
                if manager.playbackItem?.audioStreams.isNotEmpty == true {
                    Audio()
                }
            case .autoPlay:
                if manager.queue != nil {
                    AutoPlay()
                }
            case .playbackSpeed:
                if !manager.item.isLiveStream {
                    PlaybackRateMenu()
                }
            case .playbackQuality:
                if !manager.item.isLiveStream {
                    PlaybackQuality()
                }
            case .playNextItem:
                if manager.queue != nil {
                    PlayNextItem()
                }
            case .playPreviousItem:
                if manager.queue != nil {
                    PlayPreviousItem()
                }
            case .subtitles:
                if manager.playbackItem?.subtitleStreams.isNotEmpty == true {
                    Subtitles()
                }
            }
        }

        @ViewBuilder
        private var compactView: some View {
            Menu(
                "Menu",
                systemImage: "ellipsis.circle"
            ) {
                ForEach(
                    barActionButtons,
                    content: view(for:)
                )
                .environment(\.isInMenu, true)

                Divider()

                ForEach(
                    menuActionButtons,
                    content: view(for:)
                )
                .environment(\.isInMenu, true)
            }
        }

        @ViewBuilder
        private var regularView: some View {
            HStack(spacing: 0) {
                ForEach(
                    barActionButtons,
                    content: view(for:)
                )

                if menuActionButtons.isNotEmpty {
                    Menu(
                        "Menu",
                        systemImage: "ellipsis.circle"
                    ) {
                        ForEach(
                            menuActionButtons,
                            content: view(for:)
                        )
                        .environment(\.isInMenu, true)
                    }
                }
            }
        }

        var body: some View {
            if containerState.isCompact {
                compactView
            } else {
                regularView
            }
        }
    }
}

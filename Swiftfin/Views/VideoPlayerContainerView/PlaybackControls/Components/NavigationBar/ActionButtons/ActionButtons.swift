//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: ensure changes on playback item change

extension VideoPlayer.PlaybackControls.NavigationBar {

    struct ActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var rawBarActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var rawMenuActionButtons

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private func filteredActionButtons(_ rawButtons: [VideoPlayerActionButton]) -> [VideoPlayerActionButton] {
            var filteredButtons = rawButtons

            if manager.playbackItem?.audioStreams.isEmpty == true {
                filteredButtons.removeAll { $0 == .audio }
            }

            if manager.playbackItem?.subtitleStreams.isEmpty == true {
                filteredButtons.removeAll { $0 == .subtitles }
            }

            if manager.queue == nil {
                filteredButtons.removeAll { $0 == .autoPlay }
                filteredButtons.removeAll { $0 == .playNextItem }
                filteredButtons.removeAll { $0 == .playPreviousItem }
            }

            if manager.item.isLiveStream {
                filteredButtons.removeAll { $0 == .audio }
                filteredButtons.removeAll { $0 == .autoPlay }
                filteredButtons.removeAll { $0 == .playbackSpeed }
//                filteredButtons.removeAll { $0 == .playbackQuality }
                filteredButtons.removeAll { $0 == .subtitles }
            }

            return filteredButtons
        }

        private var barActionButtons: [VideoPlayerActionButton] {
            filteredActionButtons(rawBarActionButtons)
        }

        private var menuActionButtons: [VideoPlayerActionButton] {
            filteredActionButtons(rawMenuActionButtons)
        }

        @ViewBuilder
        private func view(for button: VideoPlayerActionButton) -> some View {
            switch button {
            case .aspectFill:
                AspectFill()
            case .audio:
                Audio()
            case .autoPlay:
                AutoPlay()
            case .gestureLock:
                GestureLock()
            case .playbackSpeed:
                PlaybackRateMenu()
//            case .playbackQuality:
//                PlaybackQuality()
            case .playNextItem:
                PlayNextItem()
            case .playPreviousItem:
                PlayPreviousItem()
            case .subtitles:
                Subtitles()
            }
        }

        @ViewBuilder
        private var compactView: some View {
            Menu(
                L10n.menu,
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
                        L10n.menu,
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

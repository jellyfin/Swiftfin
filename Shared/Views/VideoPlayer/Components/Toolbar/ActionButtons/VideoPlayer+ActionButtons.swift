//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: ensure changes on playback item change

extension VideoPlayer.PlaybackControls.Toolbar {

    struct ActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var rawBarActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var rawMenuActionButtons

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @FocusState
        private var focusedButton: String?

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
            case .pictureInPicture:
                PictureInPicture()
            case .playbackSpeed:
                PlaybackRateMenu()
//            case .playbackQuality:
//                PlaybackQuality()
            case .playNextItem:
                PlayNextItem()
            case .playPreviousItem:
                PlayPreviousItem()
            case .remotePlayback:
                RemotePlayback()
            case .subtitles:
                Subtitles()
            #if os(iOS)
            case .gestureLock:
                GestureLock()
            #endif
            }
        }

        @ViewBuilder
        private var compactView: some View {
            Menu(
                L10n.menu,
                systemImage: "ellipsis.circle"
            ) {
                ForEach(
                    barActionButtons.filter { VideoPlayerActionButton.allCases.contains($0) },
                    content: view(for:)
                )
                .environment(\.isInMenu, true)

                Divider()

                ForEach(
                    menuActionButtons.filter { VideoPlayerActionButton.allCases.contains($0) },
                    content: view(for:)
                )
                .environment(\.isInMenu, true)
            }
        }

        @ViewBuilder
        private var regularView: some View {
            HStack(spacing: UIDevice.isTV ? 16 : 0) {
                ForEach(barActionButtons) { button in
                    view(for: button)
                        .focused($focusedButton, equals: button.rawValue)
                }

                if menuActionButtons.isNotEmpty {
                    Menu(
                        L10n.menu,
                        systemImage: UIDevice.isTV ? "ellipsis" : "ellipsis.circle"
                    ) {
                        ForEach(
                            menuActionButtons.filter { VideoPlayerActionButton.allCases.contains($0) },
                            content: view(for:)
                        )
                        .environment(\.isInMenu, true)
                    }
                    .focused($focusedButton, equals: "menu")
                }
            }
            .focusSection()
            .backport
            .defaultFocus(
                $focusedButton,
                barActionButtons.first?.rawValue ?? "menu",
                priority: .userInitiated
            )
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

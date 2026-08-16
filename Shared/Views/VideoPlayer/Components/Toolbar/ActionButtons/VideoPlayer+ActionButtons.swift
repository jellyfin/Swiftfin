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

        private func resolvedActionButtons(_ rawButtons: [VideoPlayerActionButton]) -> [VideoPlayerActionButton] {
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
                filteredButtons.removeAll { $0 == .playbackSettings }
                filteredButtons.removeAll { $0 == .subtitles }
            }

            if let session = manager.remoteProxy {
                filteredButtons.removeAll { !session.supports($0) }
            }

            return filteredButtons
        }

        private var barActionButtons: [VideoPlayerActionButton] {
            resolvedActionButtons(rawBarActionButtons)
        }

        private var menuActionButtons: [VideoPlayerActionButton] {
            resolvedActionButtons(rawMenuActionButtons)
        }

        private var usesLiquidGlass: Bool {
            if #available(iOS 26.0, *) {
                true
            } else {
                false
            }
        }

        private var menuSystemImage: String {
            if UIDevice.isTV || usesLiquidGlass {
                "ellipsis"
            } else {
                "ellipsis.circle"
            }
        }

        private var buttonSize: CGFloat {
            VideoPlayer.PlaybackControls.Toolbar.buttonSize
        }

        private var menuLabel: some View {
            Label(L10n.menu, systemImage: menuSystemImage)
        }

        private func isMenuButton(_ button: VideoPlayerActionButton) -> Bool {
            switch button {
            case .audio, .playbackSpeed, .playbackSettings, .subtitles:
                true
            default:
                false
            }
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
            case .playbackSettings:
                PlaybackSettings()
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
            Menu {
                ForEach(
                    barActionButtons,
                    content: view(for:)
                )

                Divider()

                ForEach(
                    menuActionButtons.filter { VideoPlayerActionButton.allCases.contains($0) },
                    content: view(for:)
                )
            } label: {
                menuLabel
            }
            .frame(width: buttonSize, height: buttonSize)
            .if(usesLiquidGlass) { menu in
                menu
                    .backport
                    .glassEffect(in: .circle)
            }
            .symbolRenderingMode(.monochrome)
            .foregroundStyle(.primary, .secondary)
            .withViewContext(.isInMenu)
        }

        @ViewBuilder
        private var regularView: some View {
            HStack(spacing: VideoPlayer.PlaybackControls.Toolbar.buttonSpacing) {
                ForEach(barActionButtons) { button in
                    view(for: button)
                        .frame(width: buttonSize, height: buttonSize)
                        .if(usesLiquidGlass && isMenuButton(button)) { menu in
                            menu
                                .backport
                                .glassEffect(in: .circle)
                        }
                        .focused($focusedButton, equals: button.rawValue)
                }

                if menuActionButtons.isNotEmpty {
                    Menu {
                        ForEach(
                            menuActionButtons.filter { VideoPlayerActionButton.allCases.contains($0) },
                            content: view(for:)
                        )
                        .withViewContext(.isInMenu)
                    } label: {
                        menuLabel
                    }
                    .frame(width: buttonSize, height: buttonSize)
                    .if(usesLiquidGlass) { menu in
                        menu
                            .backport
                            .glassEffect(in: .circle)
                    }
                    .symbolRenderingMode(.monochrome)
                    .foregroundStyle(.primary, .secondary)
                    .focused($focusedButton, equals: "menu")
                }
            }
            .defaultFocus(
                $focusedButton,
                barActionButtons.first?.rawValue ?? "menu",
                priority: .userInitiated
            )
            .focusSection()
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

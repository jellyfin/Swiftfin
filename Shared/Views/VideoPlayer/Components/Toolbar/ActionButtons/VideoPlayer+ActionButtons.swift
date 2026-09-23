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

        typealias ViewState = VideoPlayer.ViewState

        private typealias Toolbar = VideoPlayer.PlaybackControls.Toolbar

        private static var buttonSpacing: CGFloat {
            if UIDevice.isTV {
                UIDevice.supportsLiquidGlass ? 20 : 16
            } else {
                UIDevice.supportsLiquidGlass ? 4 : 0
            }
        }

        @Default(.VideoPlayer.barActionButtons)
        private var rawBarActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var rawMenuActionButtons

        @Environment(ViewState.self)
        private var viewState
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
                filteredButtons.removeAll { $0 == .autoPlay }
                filteredButtons.removeAll { $0 == .playbackSpeed }
                filteredButtons.removeAll { $0 == .playbackSettings }
            }

            return filteredButtons
        }

        private var barActionButtons: [VideoPlayerActionButton] {
            resolvedActionButtons(rawBarActionButtons)
        }

        private var menuActionButtons: [VideoPlayerActionButton] {
            resolvedActionButtons(rawMenuActionButtons)
        }

        private var menuSystemImage: String {
            if UIDevice.isTV || UIDevice.supportsLiquidGlass {
                "ellipsis"
            } else {
                "ellipsis.circle"
            }
        }

        private var menuLabel: some View {
            Label(L10n.menu, systemImage: menuSystemImage)
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
            #if os(iOS)
            case .gestureLock:
                GestureLock()
            #endif
            case .playbackSpeed:
                PlaybackRateMenu()
            case .playbackSettings:
                PlaybackSettings()
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
            let barButtons = barActionButtons
            let menuButtons = menuActionButtons.subtracting(barActionButtons)

            Menu {
                ForEach(
                    barButtons,
                    content: view(for:)
                )

                if barButtons.isNotEmpty, menuButtons.isNotEmpty {
                    Divider()
                }

                ForEach(
                    menuButtons,
                    content: view(for:)
                )
            } label: {
                menuLabel
            }
            .frame(width: Toolbar.buttonSize, height: Toolbar.buttonSize)
            .withViewContext(.isInMenu)
        }

        @ViewBuilder
        private var regularView: some View {
            HStack(spacing: Self.buttonSpacing) {
                ForEach(barActionButtons) { button in
                    view(for: button)
                        .frame(width: Toolbar.buttonSize, height: Toolbar.buttonSize)
                        .coordinatedFocus(ViewState.Focus.action(button.rawValue), selection: $focusedButton)
                }

                if menuActionButtons.isNotEmpty {
                    Menu {
                        ForEach(
                            menuActionButtons,
                            content: view(for:)
                        )
                        .withViewContext(.isInMenu)
                    } label: {
                        menuLabel
                    }
                    .frame(width: Toolbar.buttonSize, height: Toolbar.buttonSize)
                    .coordinatedFocus(ViewState.Focus.action("menu"), selection: $focusedButton)
                }
            }
            .defaultFocus(
                $focusedButton,
                ViewState.Focus.action(barActionButtons.first?.rawValue ?? "menu"),
                priority: .userInitiated
            )
            .focusSection()
        }

        var body: some View {
            Group {
                if viewState.isCompact {
                    compactView
                } else {
                    regularView
                }
            }
            .modifier(VideoPlayer.PlaybackControls.OverlayBarButtonStyleModifier())
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

struct OnPressButtonStyle: ButtonStyle {

    var onPress: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed) { newValue in
                onPress(newValue)
            }
    }
}

struct BarButtonStyle: ButtonStyle {

    var onPress: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(.iconOnly)
            .frame(width: 45, height: 45)
            .contentShape(Rectangle())
            .background {
                if configuration.isPressed {
                    Circle()
                        .fill(Color.white)
                        .opacity(0.5)
                        .transition(.opacity.animation(.linear(duration: 0.2)))
                }
            }
            .onChange(of: configuration.isPressed) { newValue in
                onPress(newValue)
            }
    }
}

extension VideoPlayer.Overlay {

    struct BarActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var barActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var menuActionButtons

        @EnvironmentObject
        private var overlayTimer: PollingTimer

        @ViewBuilder
        private func view(for button: VideoPlayerActionButton) -> some View {
            switch button {
            case .aspectFill:
                ActionButtons.AspectFill()
            case .audio:
                ActionButtons.Audio()
            case .autoPlay:
                ActionButtons.AutoPlay()
            case .playbackSpeed:
                ActionButtons.PlaybackSpeedMenu()
            case .playNextItem:
                ActionButtons.PlayNextItem()
            case .playPreviousItem:
                ActionButtons.PlayPreviousItem()
            case .subtitles:
                ActionButtons.Subtitles()
            }
        }

        @ViewBuilder
        private var menuButtons: some View {
            Menu(
                "Button Menu",
                systemImage: "ellipsis.circle"
            ) {
                ForEach(menuActionButtons) { actionButton in
                    view(for: actionButton)
                }
            }
        }

        var body: some View {
            HStack(spacing: 0) {
                ForEach(barActionButtons) { actionButton in
                    view(for: actionButton)
                }

                if menuActionButtons.isNotEmpty {
                    menuButtons
                }
            }
            .buttonStyle(BarButtonStyle(onPress: { isPressed in
                if isPressed {
                    overlayTimer.stop()
                } else {
                    overlayTimer.poll()
                }
            }))
        }
    }
}

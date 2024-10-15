//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay.NavigationBar {

    struct ActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var barActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var menuActionButtons

        @EnvironmentObject
        private var overlayTimer: PokeIntervalTimer

        @ViewBuilder
        private func view(for button: VideoPlayerActionButton) -> some View {
            switch button {
            case .aspectFill: AspectFill()
            case .audio: Audio()
            case .autoPlay: AutoPlay()
            case .playbackSpeed: PlaybackRateMenu()
            case .playNextItem: PlayNextItem()
            case .playPreviousItem: PlayPreviousItem()
            case .subtitles: Subtitles()
            }
        }

        @ViewBuilder
        private var menuButtons: some View {
            Menu(
                "Menu",
                systemImage: "ellipsis.circle"
            ) {
                ForEach(menuActionButtons) { actionButton in
                    view(for: actionButton)
                }
            }
            .iOS16 { menu in
                menu
//                    .labelStyle(.iconOnly)
                        .frame(width: 40, height: 40)
                        .contentShape(Rectangle())
//                    .background {
//                        if configuration.isPressed {
//                            Circle()
//                                .fill(Color.white)
//                                .opacity(0.5)
//                                .transition(.opacity.animation(.linear(duration: 0.2).delay(0.2)))
//                        }
//                    }
//                    .onChange(of: configuration.isPressed) { newValue in
//                        onPress(newValue)
//                    }
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
        }
    }
}

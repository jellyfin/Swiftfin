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

extension VideoPlayer.Overlay {

    struct BarActionButtons: View {

        @Default(.VideoPlayer.barActionButtons)
        private var barActionButtons
        @Default(.VideoPlayer.menuActionButtons)
        private var menuActionButtons

        @EnvironmentObject
        private var overlayTimer: DelayIntervalTimer

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
        }
    }
}

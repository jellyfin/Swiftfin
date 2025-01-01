//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay {

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
//            case .aspectFill: AspectFill()
//            case .audio: Audio()
//            case .autoPlay: AutoPlay()
//            case .playbackSpeed: PlaybackRateMenu()
//            case .playNextItem: PlayNextItem()
//            case .playPreviousItem: PlayPreviousItem()
//            case .subtitles: Subtitles()
            default: EmptyView()
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

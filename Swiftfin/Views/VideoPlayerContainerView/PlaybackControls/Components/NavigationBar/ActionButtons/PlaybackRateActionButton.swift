//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: set through proxy

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlaybackRateMenu: View {

        @Default(.VideoPlayer.Playback.rates)
        private var rates: [Float]

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            Menu(
                L10n.playbackSpeed,
                systemImage: VideoPlayerActionButton.playbackSpeed.systemImage
            ) {
                Picker(L10n.playbackSpeed, selection: $manager.rate) {
                    ForEach(rates, id: \.self) { rate in
                        Text(rate, format: .playbackRate)
                            .tag(rate)
                    }

                    if !rates.contains(manager.rate) {
                        Divider()

                        Text(manager.rate, format: .playbackRate)
                            .tag(manager.rate)
                    }
                }
            }
        }
    }
}

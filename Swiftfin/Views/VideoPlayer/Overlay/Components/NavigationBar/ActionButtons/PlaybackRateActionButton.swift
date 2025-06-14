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

extension VideoPlayer.Overlay.NavigationBar.ActionButtons {

    struct PlaybackRateMenu: View {

        @Default(.VideoPlayer.Playback.rates)
        private var rates: [Float]

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            Menu(
                L10n.playbackSpeed,
                systemImage: "speedometer"
            ) {
                ForEach(rates, id: \.self) { rate in
                    Button {
                        manager.set(rate: rate)
                    } label: {
                        if rate == manager.rate {
                            Label("\(rate, format: .playbackRate)", systemImage: "checkmark")
                        } else {
                            Text(rate, format: .playbackRate)
                        }
                    }
                }

                if !rates.contains(manager.rate) {
                    Divider()

                    Label(
                        "\(manager.rate, format: .playbackRate)",
                        systemImage: "checkmark"
                    )
                }
            }
        }
    }
}

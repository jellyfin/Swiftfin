//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PlaybackRateMenu: View {

        @Default(.VideoPlayer.Playback.rates)
        private var rates: [Double]

        @Environment(ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        var body: some View {
            @Bindable
            var mediaSession = mediaSession
            let supportedRates = mediaSession.player?.supportedRates ?? 0.1 ... 5
            let selection = Binding(get: { mediaSession.effectiveRate }, set: { mediaSession.rate = $0 })

            Menu(
                L10n.playbackSpeed,
                systemImage: VideoPlayerActionButton.playbackSpeed.systemImage
            ) {
                Picker(L10n.playbackSpeed, selection: selection) {
                    ForEach(rates.filter { supportedRates.contains($0) }, id: \.self) { rate in
                        Text(rate, format: .playbackRate)
                            .tag(rate)
                    }

                    if !rates.contains(mediaSession.effectiveRate) {
                        Divider()

                        Text(mediaSession.effectiveRate, format: .playbackRate)
                            .tag(mediaSession.effectiveRate)
                    }
                }

                Divider()

                Button(L10n.custom) {
                    viewState.presentGuestSupplement(PlaybackAdjustmentSupplement.playbackSpeed(range: supportedRates))
                }
            }
        }
    }
}

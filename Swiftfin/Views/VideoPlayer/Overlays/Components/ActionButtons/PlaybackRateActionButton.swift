//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay.NavigationBar.ActionButtons {

    struct PlaybackRateMenu: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            Menu(
                L10n.playbackSpeed,
                systemImage: "speedometer"
            ) {
//                Section(L10n.playbackSpeed) {
//                    Button("Test") {}
//                    Button("Test") {}
//                    Button("Test") {}
//                }

                Button("\(PlaybackRate.one.rate, format: .rate)") {
                    manager.playbackRate = .one
                }

                Button("\(PlaybackRate.two.rate, format: .rate)") {
                    manager.playbackRate = .two
                }
            }
        }
    }
}

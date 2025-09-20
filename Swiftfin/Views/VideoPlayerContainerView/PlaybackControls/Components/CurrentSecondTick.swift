//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls {

    // TODO: make option
    struct CurrentSecondTick: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var activeSeconds: Duration = .zero

        var body: some View {
            if let runtime = manager.item.runtime, runtime > .zero {
                GeometryReader { proxy in
                    Color.white
                        .frame(width: 1.5)
                        .offset(x: proxy.size.width * (activeSeconds / runtime) - 0.75)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .assign(manager.secondsBox.$value, to: $activeSeconds)
            }
        }
    }
}

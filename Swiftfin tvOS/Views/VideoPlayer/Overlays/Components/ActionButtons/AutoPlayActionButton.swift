//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay.ActionButtons {

    struct AutoPlay: View {

        @Default(.VideoPlayer.autoPlayEnabled)
        private var autoPlayEnabled

        @EnvironmentObject
        private var overlayTimer: TimerProxy

        var body: some View {
            SFSymbolButton(
                systemName: autoPlayEnabled ? "play.circle.fill" : "stop.circle"
            )
            .onSelect {
                autoPlayEnabled.toggle()
                overlayTimer.start(5)
            }
            .frame(maxWidth: 30, maxHeight: 30)
        }
    }
}

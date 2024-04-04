//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay.ActionButtons {

    struct AutoPlay: View {

        @Default(.VideoPlayer.autoPlayEnabled)
        private var autoPlayEnabled

        @EnvironmentObject
        private var overlayTimer: TimerProxy

        private var content: (Bool) -> any View

        var body: some View {
            Button {
                autoPlayEnabled.toggle()
                overlayTimer.start(5)
            } label: {
                content(autoPlayEnabled)
                    .eraseToAnyView()
            }
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.AutoPlay {

    init(@ViewBuilder _ content: @escaping (Bool) -> any View) {
        self.content = content
    }
}

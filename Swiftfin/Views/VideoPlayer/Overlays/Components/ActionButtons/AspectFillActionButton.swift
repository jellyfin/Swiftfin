//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay.ActionButtons {

    struct AspectFill: View {

        @Environment(\.aspectFilled)
        @Binding
        private var aspectFilled: Bool

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy

        private var content: (Bool) -> any View

        var body: some View {
            Button {
                overlayTimer.start(5)
                aspectFilled.toggle()
            } label: {
                content(aspectFilled).eraseToAnyView()
            }
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.AspectFill {

    init(@ViewBuilder _ content: @escaping (Bool) -> any View) {
        self.content = content
    }
}

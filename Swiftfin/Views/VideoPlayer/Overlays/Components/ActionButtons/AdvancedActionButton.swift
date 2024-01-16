//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay.ActionButtons {

    struct Advanced: View {

        @Environment(\.aspectFilled)
        @Binding
        private var aspectFilled: Bool

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var splitViewProxy: SplitContentViewProxy

        private var content: () -> any View

        var body: some View {
            Button {
                overlayTimer.start(5)
                splitViewProxy.present()
            } label: {
                content().eraseToAnyView()
            }
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.Advanced {

    init(@ViewBuilder _ content: @escaping () -> any View) {
        self.content = content
    }
}

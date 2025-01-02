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

    struct Chapters: View {

        @Default(.VideoPlayer.autoPlayEnabled)
        private var autoPlayEnabled

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType

        @EnvironmentObject
        private var overlayTimer: TimerProxy

        private var content: () -> any View

        var body: some View {
            Button {
                currentOverlayType = .chapters
                overlayTimer.stop()
            } label: {
                content()
                    .eraseToAnyView()
            }
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.Chapters {

    init(@ViewBuilder _ content: @escaping () -> any View) {
        self.content = content
    }
}

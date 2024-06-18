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

    struct LockOverlay: View {

        @Default(.VideoPlayer.lockOverlayEnabled)
        private var lockOverlayEnabled

        private var content: (Bool) -> any View

        var body: some View {
            Button {
                lockOverlayEnabled.toggle()
            } label: {
                content(lockOverlayEnabled)
                    .eraseToAnyView()
            }
        }
    }
}

extension VideoPlayer.Overlay.ActionButtons.LockOverlay {

    init(@ViewBuilder _ content: @escaping (Bool) -> any View) {
        self.content = content
    }
}

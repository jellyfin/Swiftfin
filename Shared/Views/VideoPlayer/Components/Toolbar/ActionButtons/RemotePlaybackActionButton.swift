//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct RemotePlayback: View {

        @Router
        private var router

        var body: some View {
            Button {
                router.route(to: .remotePlayback)
            } label: {
                Label(L10n.castToDevice, systemImage: "airplayvideo")
                    .labelStyle(.iconOnly)
                    .foregroundStyle(.white)
                    .videoPlayerActionButtonTransition()
            }
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay.NavigationBar.ActionButtons {

    struct PlayPreviousItem: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            Button(
                L10n.playNextItem,
                systemImage: "backward.end.circle.fill"
            ) {
                // TODO: work
            }
            .disabled(!(manager.queue?.hasPreviousItem ?? false))
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay.NavigationBar.ActionButtons {

    struct PlayPreviousItem: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            RoundActionButton(
                L10n.playNextItem,
                systemImage: "backward.end.circle.fill"
            ) {
                guard let previousItem = manager.queue?.previousItem else { return }
                manager.send(.playNew(item: previousItem))
            }
            .disabled(manager.queue?.hasPreviousItem == false)
        }
    }
}

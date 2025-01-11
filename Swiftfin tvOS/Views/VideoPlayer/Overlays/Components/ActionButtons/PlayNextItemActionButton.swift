//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.Overlay.NavigationBar.ActionButtons {

    struct PlayNextItem: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            RoundActionButton(
                L10n.playNextItem,
                systemImage: "forward.end.circle.fill"
            ) {
                guard let nextItem = manager.queue?.nextItem else { return }
                manager.send(.playNew(item: nextItem))
            }
            .disabled(manager.queue?.hasNextItem == false)
        }
    }
}

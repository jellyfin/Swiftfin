//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct AudioOffset: View {

        @ViewContextContains(.isInMenu)
        private var isInMenu

        @Environment(ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        var body: some View {
            Button {
                viewState.presentGuestSupplement(PlaybackAdjustmentSupplement.audioOffset)
            } label: {
                Label(
                    L10n.audioOffset,
                    systemImage: VideoPlayerActionButton.audioOffset.systemImage
                )

                if isInMenu {
                    Text(mediaSession.playbackItem?.audioOffset ?? .zero, format: .playbackOffset)
                }
            }
        }
    }
}

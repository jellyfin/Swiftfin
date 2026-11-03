//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct SubtitleOffset: View {

        @ViewContextContains(.isInMenu)
        private var isInMenu

        @Environment(ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        private var primaryOffsetButton: some View {
            Button {
                viewState.presentGuestSupplement(PlaybackAdjustmentSupplement.subtitleOffset)
            } label: {
                if isInMenu {
                    Text(L10n.subtitleOffset)

                    Text(mediaSession.playbackItem?.subtitleOffset ?? .zero, format: .playbackOffset)
                } else {
                    Label(
                        L10n.subtitleOffset,
                        systemImage: VideoPlayerActionButton.subtitleOffset.systemImage
                    )
                }
            }
        }

        var body: some View {
            if mediaSession.playbackItem?.supportsSecondarySubtitles == true {
                Menu(L10n.subtitleOffset, systemImage: VideoPlayerActionButton.subtitleOffset.systemImage) {
                    primaryOffsetButton

                    Button {
                        viewState.presentGuestSupplement(PlaybackAdjustmentSupplement.secondarySubtitleOffset)
                    } label: {
                        Text(L10n.secondarySubtitleOffset)

                        Text(mediaSession.playbackItem?.secondarySubtitleOffset ?? .zero, format: .playbackOffset)
                    }
                }
                .menuOrder(.fixed)
            } else {
                primaryOffsetButton
            }
        }
    }
}

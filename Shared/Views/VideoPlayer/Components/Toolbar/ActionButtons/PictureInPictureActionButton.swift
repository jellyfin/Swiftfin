//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PictureInPicture: View {

        @Environment(MediaSession.self)
        private var mediaSession

        private var isPiPActive: Bool {
            (mediaSession.player as? MediaPlayerPictureInPictureProviding)?.isPiPActive == true
        }

        private var systemImage: String {
            if isPiPActive {
                VideoPlayerActionButton.pictureInPicture.secondarySystemImage
            } else {
                VideoPlayerActionButton.pictureInPicture.systemImage
            }
        }

        var body: some View {
            if mediaSession.player is any MediaPlayerPictureInPictureProviding {
                Button(L10n.pictureInPicture, systemImage: systemImage) {
                    if isPiPActive {
                        mediaSession.stopPictureInPicture()
                    } else {
                        mediaSession.startPictureInPicture()
                    }
                }
            }
        }
    }
}

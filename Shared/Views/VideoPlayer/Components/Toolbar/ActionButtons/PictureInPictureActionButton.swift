//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PictureInPicture: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            if let pipProxy = manager.proxy as? MediaPlayerPictureInPictureCapable {
                Button(L10n.pictureInPicture, systemImage: VideoPlayerActionButton.pictureInPicture.systemImage) {
                    pipProxy.startPiP()
                }
                .videoPlayerActionButtonTransition()
            }
        }
    }
}

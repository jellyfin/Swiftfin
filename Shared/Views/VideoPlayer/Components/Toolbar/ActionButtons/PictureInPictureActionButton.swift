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

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var isPiPActive: Bool = false
        @State
        private var isPiPAvailable: Bool = false

        private var systemImage: String {
            if isPiPActive {
                VideoPlayerActionButton.pictureInPicture.secondarySystemImage
            } else {
                VideoPlayerActionButton.pictureInPicture.systemImage
            }
        }

        var body: some View {
            if let pipProxy = manager.proxy as? MediaPlayerPictureInPictureCapable {
                Group {
                    if isPiPAvailable {
                        Button(L10n.pictureInPicture, systemImage: systemImage) {
                            if isPiPActive {
                                pipProxy.stopPiP()
                            } else {
                                pipProxy.startPiP()
                            }
                        }
                        .videoPlayerActionButtonTransition()
                    }
                }
                .assign(pipProxy.isPiPActive.$value, to: $isPiPActive)
                .assign(pipProxy.isPiPAvailable.$value, to: $isPiPAvailable)
            }
        }
    }
}

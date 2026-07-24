//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PictureInPicture: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var isPiPActive: Bool = false

        private var systemImage: String {
            if isPiPActive {
                VideoPlayerActionButton.pictureInPicture.secondarySystemImage
            } else {
                VideoPlayerActionButton.pictureInPicture.systemImage
            }
        }

        private var isPiPActivePublisher: AnyPublisher<Bool, Never> {
            (manager.proxy as? MediaPlayerPictureInPictureCapable)?
                .isPiPActive
                .$value
                .eraseToAnyPublisher()
                ?? Just(false).eraseToAnyPublisher()
        }

        var body: some View {
            if manager.proxy is any MediaPlayerPictureInPictureCapable {
                Button(L10n.pictureInPicture, systemImage: systemImage) {
                    if isPiPActive {
                        manager.stopPictureInPicture()
                    } else {
                        manager.startPictureInPicture()
                    }
                }
                .videoPlayerActionButtonTransition()
                .onReceive(isPiPActivePublisher) { isPiPActive = $0 }
            }
        }
    }
}

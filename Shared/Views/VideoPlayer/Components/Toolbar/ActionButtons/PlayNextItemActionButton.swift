//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PlayNextItem: View {

        @Environment(MediaSession.self)
        private var mediaSession

        var body: some View {
            if let queue = mediaSession.queue {
                _PlayNextItem(queue: queue)
            }
        }
    }

    private struct _PlayNextItem: View {

        @Environment(MediaSession.self)
        private var mediaSession

        let queue: any MediaPlayerQueue

        var body: some View {
            Button(
                L10n.playNextItem,
                systemImage: VideoPlayerActionButton.playNextItem.systemImage
            ) {
                guard let nextItem = queue.nextItem else { return }

                mediaSession.playNewItem(intent: nextItem)
            }
            .disabled(queue.nextItem == nil)
        }
    }
}

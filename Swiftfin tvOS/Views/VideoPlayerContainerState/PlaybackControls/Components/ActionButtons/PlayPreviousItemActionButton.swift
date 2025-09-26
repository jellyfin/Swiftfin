//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.NavigationBar.ActionButtons {

    struct PlayPreviousItem: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            if let queue = manager.queue {
                _PlayPreviousItem(queue: queue)
            }
        }
    }

    private struct _PlayPreviousItem: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var queue: AnyMediaPlayerQueue

        var body: some View {
            Button(
                L10n.playPreviousItem,
                systemImage: VideoPlayerActionButton.playPreviousItem.systemImage
            ) {
                guard let previousItem = queue.previousItem else { return }
                manager.playNewItem(provider: previousItem)
            }
            .disabled(queue.previousItem == nil)
        }
    }
}

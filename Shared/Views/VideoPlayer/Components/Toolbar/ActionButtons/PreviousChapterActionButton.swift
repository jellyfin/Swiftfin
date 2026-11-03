//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct PreviousChapter: View {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        var body: some View {
            if let supplement = viewState.supplements.compactMap({ $0 as? MediaChaptersSupplement }).first {
                Button(
                    L10n.previousChapter,
                    systemImage: VideoPlayerActionButton.previousChapter.systemImage
                ) {
                    guard let start = supplement.chapters.previousChapterStart(before: mediaSession.seconds) else { return }

                    mediaSession.seek(to: start)
                    mediaSession.setPlaybackRequestStatus(status: .playing)
                }
                .disabled(supplement.chapters.previousChapterStart(before: mediaSession.seconds) == nil)
            }
        }
    }
}

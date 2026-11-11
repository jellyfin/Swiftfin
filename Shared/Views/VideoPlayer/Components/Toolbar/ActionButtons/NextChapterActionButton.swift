//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer.PlaybackControls.Toolbar.ActionButtons {

    struct NextChapter: View {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        @ContentBuilder
        var body: some View {
            if let supplement = viewState.supplements.compactMap({ $0 as? MediaChaptersSupplement }).first {
                Button(
                    L10n.nextChapter,
                    systemImage: VideoPlayerActionButton.nextChapter.systemImage
                ) {
                    guard let start = supplement.nextChapterStart(after: mediaSession.seconds) else { return }

                    mediaSession.seek(to: start)
                    mediaSession.setPlaybackRequestStatus(status: .playing)
                }
                .disabled(supplement.nextChapterStart(after: mediaSession.seconds) == nil)
            }
        }
    }
}

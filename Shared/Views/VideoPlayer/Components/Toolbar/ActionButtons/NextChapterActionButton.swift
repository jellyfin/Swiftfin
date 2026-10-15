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

        @EnvironmentObject
        private var manager: MediaPlayerManager

        var body: some View {
            if let supplement = manager.supplements
                .compactMap({ $0 as? MediaChaptersSupplement })
                .first
            {
                _NextChapter(supplement: supplement)
            }
        }
    }

    private struct _NextChapter: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var supplement: MediaChaptersSupplement

        @State
        private var currentSeconds: Duration = .zero

        var body: some View {
            Button(
                L10n.nextChapter,
                systemImage: VideoPlayerActionButton.nextChapter.systemImage
            ) {
                guard let start = supplement.nextChapterStart(after: currentSeconds) else { return }

                manager.proxy?.setSeconds(start)
                manager.setPlaybackRequestStatus(status: .playing)
            }
            .disabled(supplement.nextChapterStart(after: currentSeconds) == nil)
            .onReceive(manager.secondsBox.$value) { seconds in
                currentSeconds = seconds
            }
        }
    }
}

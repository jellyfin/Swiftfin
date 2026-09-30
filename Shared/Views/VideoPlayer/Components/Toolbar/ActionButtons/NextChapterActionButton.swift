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

        @State
        private var hasNextChapter = false
        @State
        private var isInIntro = false

        private func update(for seconds: Duration) {
            let navigator = manager.chapterNavigator
            hasNextChapter = navigator.nextChapter(after: seconds) != nil
            isInIntro = navigator.isInIntro(at: seconds)
        }

        private func skipToNextChapter() {
            guard let nextChapter = manager.chapterNavigator.nextChapter(after: manager.seconds) else { return }
            manager.seek(to: nextChapter)
        }

        var body: some View {
            Button(
                isInIntro ? L10n.skipIntro : L10n.nextChapter,
                systemImage: VideoPlayerActionButton.nextChapter.systemImage,
                action: skipToNextChapter
            )
            .disabled(!hasNextChapter)
            .onReceive(manager.secondsBox.$value, perform: update(for:))
        }
    }
}

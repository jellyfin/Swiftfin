//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension VideoPlayer.UIVideoPlayerContainerViewController.SupplementContainerView {

    struct SupplementChapterHStack: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager

        let chapters: [ChapterInfo.FullInfo]

        var body: some View {
            PosterHStack(
                type: .landscape,
                items: chapters
            ) { chapter in
                guard let startSeconds = chapter.chapterInfo.startSeconds else { return }
                manager.proxy?.setSeconds(startSeconds)
                manager.setPlaybackRequestStatus(status: .playing)
            } label: { chapter in
                MediaChaptersSupplement.ChapterLabel(chapter: chapter)
            }
        }
    }
}

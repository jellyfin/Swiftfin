//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

@MainActor
struct MediaChaptersSupplement {

    let displayTitle: String = L10n.chapters
    let id: String
    let chapters: [ChapterInfo.FullInfo]

    func chapterID(at seconds: Duration) -> ChapterInfo.FullInfo.ID? {
        chapters.chapterIndex(at: seconds).map { chapters[$0].id }
    }
}

extension MediaChaptersSupplement: VideoPlayerSupplement {

    var body: some View {
        ChapterOverlay(supplement: self)
    }

    private struct ChapterOverlay: View {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        var supplement: MediaChaptersSupplement

        private func select(chapter: ChapterInfo.FullInfo) {
            guard let startSeconds = chapter.chapterInfo.startSeconds else { return }

            mediaSession.seek(to: startSeconds)
            mediaSession.setPlaybackRequestStatus(status: .playing)
        }

        var body: some View {
            VideoPlayer.PosterCollectionView(
                data: supplement.chapters,
                currentElementID: supplement.chapterID(at: mediaSession.seconds),
                isCompact: viewState.isCompact,
                action: select
            )
        }
    }
}

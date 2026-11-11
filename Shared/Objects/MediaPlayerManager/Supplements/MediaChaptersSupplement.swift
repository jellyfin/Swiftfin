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
        let started = chapters.split(after: seconds, sortedBy: \.startSeconds).atOrBefore
        return (started.last ?? chapters.first)?.id
    }

    func nextChapterStart(after seconds: Duration) -> Duration? {
        chapters.split(after: seconds, sortedBy: \.startSeconds).after.first?.startSeconds
    }

    func previousChapterStart(before seconds: Duration) -> Duration? {
        let started = chapters.split(after: seconds, sortedBy: \.startSeconds).atOrBefore
        guard let current = started.last else { return chapters.first?.startSeconds }

        // Restart the current chapter once playback is more than three seconds into it.
        if seconds - current.startSeconds > .seconds(3) {
            return current.startSeconds
        }

        return started.dropLast().last?.startSeconds ?? current.startSeconds
    }
}

extension MediaChaptersSupplement: VideoPlayerSupplement {

    @ContentBuilder
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

        @ContentBuilder
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

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

class MediaChaptersSupplement: ObservableObject, MediaPlayerSupplement {

    let chapters: [ChapterInfo.FullInfo]
    let displayTitle: String = L10n.chapters
    let id: String

    @Published
    var activeChapterID: ChapterInfo.FullInfo.ID?

    init(chapters: [ChapterInfo.FullInfo]) {
        self.chapters = chapters
        self.id = "Chapters-\(chapters.hashValue)"
    }

    func chapterID(at seconds: Duration) -> ChapterInfo.FullInfo.ID? {
        guard let nextIndex = chapters.firstIndex(where: {
            guard let startSeconds = $0.chapterInfo.startSeconds else { return false }

            return startSeconds > seconds
        }) else {
            return chapters.last?.id
        }

        return chapters[safe: max(0, nextIndex - 1)]?.id
    }

    var videoPlayerBody: some PlatformView {
        ChapterOverlay(supplement: self)
    }
}

extension MediaChaptersSupplement {

    private struct ChapterOverlay: PlatformView {

        @Environment(VideoPlayer.ViewState.self)
        private var viewState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        var supplement: MediaChaptersSupplement

        private func select(chapter: ChapterInfo.FullInfo) {
            guard let startSeconds = chapter.chapterInfo.startSeconds else { return }

            manager.proxy?.setSeconds(startSeconds)
            manager.setPlaybackRequestStatus(status: .playing)
        }

        @ViewBuilder
        private var content: some View {
            VideoPlayer.PosterCollectionView(
                data: supplement.chapters,
                currentElementID: supplement.activeChapterID,
                isCompact: viewState.isCompact,
                action: select
            )
            .onReceive(manager.secondsBox.$value) { seconds in
                let newID = supplement.chapterID(at: seconds)
                if newID != supplement.activeChapterID {
                    supplement.activeChapterID = newID
                }
            }
        }

        var iOSView: some View {
            content
        }

        var tvOSView: some View {
            content
        }
    }
}

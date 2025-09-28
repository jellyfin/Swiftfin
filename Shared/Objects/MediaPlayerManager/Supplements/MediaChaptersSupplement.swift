//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: current button
// TODO: scroll to current chapter on appear
// TODO: fix swapping between chapters on selection
//       - little flicker at seconds boundary
// TODO: sometimes safe area for CollectionHStack doesn't trigger
// TODO: fix chapter image aspect fit
//       - still be in a 1.77 box

class MediaChaptersSupplement: ObservableObject, MediaPlayerSupplement {

    let chapters: [ChapterInfo.FullInfo]
    let displayTitle: String = L10n.chapters
    let id: String

    init(chapters: [ChapterInfo.FullInfo]) {
        self.chapters = chapters
        self.id = "Chapters-\(chapters.hashValue)"
    }

    func isCurrentChapter(seconds: Duration, chapter: ChapterInfo.FullInfo) -> Bool {
        guard let currentChapterIndex = chapters
            .firstIndex(where: {
                guard let startSeconds = $0.chapterInfo.startSeconds else { return false }
                return startSeconds > seconds
            }
            ) else { return false }

        guard let currentChapter = chapters[safe: max(0, currentChapterIndex - 1)] else { return false }
        return currentChapter.id == chapter.id
    }

    var videoPlayerBody: some PlatformView {
        ChapterOverlay(supplement: self)
    }
}

extension MediaChaptersSupplement {

    private struct ChapterOverlay: PlatformView {

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        private var supplement: MediaChaptersSupplement

        @StateObject
        private var collectionHStackProxy: CollectionHStackProxy = .init()

        init(supplement: MediaChaptersSupplement) {
            self.supplement = supplement
        }

        private var chapters: [ChapterInfo.FullInfo] {
            supplement.chapters
        }

        private var currentChapter: ChapterInfo.FullInfo? {
            chapters.first(
                where: {
                    guard let startSeconds = $0.chapterInfo.startSeconds else { return false }
                    return startSeconds <= manager.seconds
                }
            )
        }

        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
        }

        @ViewBuilder
        private var iOSCompactView: some View {
            // TODO: scroll to current chapter
            CollectionVGrid(
                uniqueElements: chapters,
                layout: .columns(
                    1,
                    insets: .init(top: 0, leading: 0, bottom: EdgeInsets.edgePadding, trailing: 0)
                )
            ) { chapter, _ in
                ChapterRow(chapter: chapter) {
                    guard let startSeconds = chapter.chapterInfo.startSeconds else { return }
                    manager.proxy?.setSeconds(startSeconds)
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                .edgePadding(.horizontal)
                .environmentObject(supplement)
            }
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            // TODO: change to continuousLeadingEdge after
            // layout inset fix in CollectionHStack
            CollectionHStack(
                uniqueElements: chapters
            ) { chapter in
                ChapterButton(chapter: chapter) {
                    guard let startSeconds = chapter.chapterInfo.startSeconds else { return }
                    manager.proxy?.setSeconds(startSeconds)
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                .frame(height: 150)
                .environmentObject(supplement)
            }
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            .proxy(collectionHStackProxy)
            .frame(height: 150)
            .onAppear {
                guard let currentChapter else { return }
                collectionHStackProxy.scrollTo(id: currentChapter.id)
            }
        }

        var tvOSView: some View { EmptyView() }
    }

    struct ChapterPreview: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

        let chapter: ChapterInfo.FullInfo

        var body: some View {
            PosterImage(
                item: chapter,
                type: .landscape,
                contentMode: .fill
            )
            .overlay {
                if isSelected {
                    ContainerRelativeShape()
                        .stroke(
                            accentColor,
                            lineWidth: 8
                        )
                        .clipped()
                }
            }
            .posterStyle(.landscape)
        }
    }

    struct ChapterContent: View {

        let chapter: ChapterInfo.FullInfo

        var body: some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(chapter.chapterInfo.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .frame(height: 15)

                Text(chapter.chapterInfo.startSeconds ?? .zero, format: .runtime)
                    .frame(height: 20)
                    .foregroundStyle(Color(UIColor.systemBlue))
                    .padding(.horizontal, 4)
                    .background {
                        Color(.darkGray)
                            .opacity(0.2)
                            .cornerRadius(4)
                    }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .font(.subheadline)
            .fontWeight(.semibold)
        }
    }

    struct ChapterRow: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var supplement: MediaChaptersSupplement

        @State
        private var activeSeconds: Duration = .zero

        let chapter: ChapterInfo.FullInfo
        let action: () -> Void

        private var isCurrentChapter: Bool {
            supplement.isCurrentChapter(
                seconds: activeSeconds,
                chapter: chapter
            )
        }

        var body: some View {
            ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                ChapterPreview(
                    chapter: chapter
                )
                .frame(width: 110)
                .padding(.vertical, 8)
            } content: {
                ChapterContent(chapter: chapter)
            }
            .onSelect(perform: action)
            .assign(manager.secondsBox.$value, to: $activeSeconds)
            .isSelected(isCurrentChapter)
        }
    }

    struct ChapterButton: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var supplement: MediaChaptersSupplement

        @State
        private var activeSeconds: Duration = .zero

        let chapter: ChapterInfo.FullInfo
        let action: () -> Void

        private var isCurrentChapter: Bool {
            supplement.isCurrentChapter(
                seconds: activeSeconds,
                chapter: chapter
            )
        }

        var body: some View {
            Button(action: action) {
                VStack(alignment: .leading, spacing: 5) {
                    ChapterPreview(
                        chapter: chapter
                    )

                    ChapterContent(
                        chapter: chapter
                    )
                }
                .font(.subheadline)
                .fontWeight(.semibold)
            }
            .foregroundStyle(.primary, .secondary)
            .assign(manager.secondsBox.$value, to: $activeSeconds)
            .isSelected(isCurrentChapter)
        }
    }
}

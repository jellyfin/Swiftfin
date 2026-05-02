//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

// TODO: scroll to current chapter on appear
// TODO: sometimes safe area for CollectionHStack doesn't trigger

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

        @Environment(\.safeAreaInsets)
        private var safeAreaInsets: EdgeInsets

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ObservedObject
        private var supplement: MediaChaptersSupplement

        //        @StateObject
        //        private var collectionHStackProxy: CollectionHStackProxy = .init()
        //        @StateObject
        //        private var collectionVGridProxy: CollectionVGridProxy = .init()

        init(supplement: MediaChaptersSupplement) {
            self.supplement = supplement
        }

        private var chapters: [ChapterInfo.FullInfo] {
            supplement.chapters
        }

        private var activeChapter: ChapterInfo.FullInfo? {
            guard let id = supplement.activeChapterID else { return nil }
            return chapters.first { $0.id == id }
        }

        private func updateActiveChapter(for seconds: Duration) {
            let newID = supplement.chapterID(at: seconds)
            if newID != supplement.activeChapterID {
                supplement.activeChapterID = newID
            }
        }

        var iOSView: some View {
            CompactOrRegularView(
                isCompact: containerState.isCompact
            ) {
                iOSCompactView
            } regularView: {
                iOSRegularView
            }
            .onReceive(manager.secondsBox.$value, perform: updateActiveChapter(for:))
        }

        @ViewBuilder
        private var iOSCompactView: some View {
            // TODO: Scroll to current chapter
            CollectionVGrid(
                uniqueElements: chapters,
                id: \.unwrappedIDHashOrZero,
                layout: .columns(
                    1,
                    insets: .init(EdgeInsets.edgePadding)
                )
            ) { chapter, _ in
                ChapterRow(supplement: supplement, chapter: chapter) {
                    guard let startSeconds = chapter.chapterInfo.startSeconds else { return }
                    manager.proxy?.setSeconds(startSeconds)
                    manager.setPlaybackRequestStatus(status: .playing)
                }
            }
            //            .proxy(collectionVGridProxy)
            //            .onAppear {
            //                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            //                    guard let currentChapter else { return }
            //                    collectionVGridProxy.scrollTo(id: currentChapter.unwrappedIDHashOrZero, animated: false)
            //                }
            //            }
        }

        @ViewBuilder
        private var iOSRegularView: some View {
            // TODO: Scroll to current chapter
            CollectionHStack(
                uniqueElements: chapters,
                id: \.unwrappedIDHashOrZero,
                layout: .minimumWidth(columnWidth: 170, rows: 1)
            ) { chapter in
                ChapterButton(supplement: supplement, chapter: chapter) {
                    guard let startSeconds = chapter.chapterInfo.startSeconds else { return }
                    manager.proxy?.setSeconds(startSeconds)
                    manager.setPlaybackRequestStatus(status: .playing)
                }
            }
            .clipsToBounds(false)
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            .itemSpacing(EdgeInsets.edgePadding / 2)
            .scrollBehavior(.continuousLeadingEdge)
        }

        var tvOSView: some View {
            CollectionVGrid(
                uniqueElements: chapters,
                id: \.unwrappedIDHashOrZero,
                layout: .columns(
                    5,
                    insets: .init(EdgeInsets.edgePadding),
                    itemSpacing: EdgeInsets.edgePadding,
                    lineSpacing: EdgeInsets.edgePadding
                )
            ) { chapter in
                ChapterButton(supplement: supplement, chapter: chapter) {
                    guard let startSeconds = chapter.chapterInfo.startSeconds else { return }
                    manager.proxy?.setSeconds(startSeconds)
                    manager.setPlaybackRequestStatus(status: .playing)
                }
            }
            .ignoresSafeArea(.container, edges: .horizontal)
            .focusSection()
            .onReceive(manager.secondsBox.$value, perform: updateActiveChapter(for:))
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
                                lineWidth: UIDevice.isTV ? 12 : 8
                            )
                            .clipped()
                    }
                }
                .posterStyle(.landscape)
                .posterShadow()
                .hoverEffect(.highlight)
            }
        }

        struct ChapterContent: View {

            let chapter: ChapterInfo.FullInfo

            var body: some View {
                VStack(alignment: .leading, spacing: 5) {
                    Text(chapter.chapterInfo.displayTitle)
                        .font(.subheadline.weight(.semibold))
                        .fontWeight(.semibold)
                        .foregroundStyle(.primary)
                        .lineLimit(1)

                    Text(chapter.chapterInfo.startSeconds ?? .zero, format: .runtime)
                        .font(UIDevice.isTV ? .caption : .subheadline.weight(.semibold))
                        .foregroundStyle(Color(UIColor.systemBlue))
                        .padding(.horizontal, 4)
                        .background {
                            Color(.darkGray)
                                .opacity(0.2)
                                .cornerRadius(4)
                        }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }

        struct ChapterRow: View {

            @ObservedObject
            var supplement: MediaChaptersSupplement

            let chapter: ChapterInfo.FullInfo
            let action: () -> Void

            var body: some View {
                ListRow(insets: .init(horizontal: EdgeInsets.edgePadding)) {
                    ChapterPreview(chapter: chapter)
                        .frame(width: 110)
                        .padding(.vertical, 8)
                } content: {
                    ChapterContent(chapter: chapter)
                }
                .onSelect(perform: action)
                .isSelected(chapter.id == supplement.activeChapterID)
            }
        }

        struct ChapterButton: View {

            @ObservedObject
            var supplement: MediaChaptersSupplement

            let chapter: ChapterInfo.FullInfo
            let action: () -> Void

            var body: some View {
                SupplementPosterButton(
                    item: chapter,
                    action: action
                ) {
                    ChapterContent(chapter: chapter)
                }
                .isSelected(chapter.id == supplement.activeChapterID)
            }
        }
    }
}

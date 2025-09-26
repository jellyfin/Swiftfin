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

struct MediaChaptersSupplement: MediaPlayerSupplement {

    let chapters: [ChapterInfo.FullInfo]
    let displayTitle: String = L10n.chapters

    var id: String {
        "Chapters-\(chapters.hashValue)"
    }

    var videoPlayerBody: some PlatformView {
        ChapterOverlay(chapters: chapters)
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

        @StateObject
        private var collectionHStackProxy: CollectionHStackProxy = .init()

        let chapters: [ChapterInfo.FullInfo]

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
                    manager.proxy?.setSeconds(chapter.secondsRange.lowerBound)
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                .edgePadding(.horizontal)
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
                    manager.proxy?.setSeconds(chapter.secondsRange.lowerBound)
                    manager.setPlaybackRequestStatus(status: .playing)
                }
                .frame(height: 150)
            }
            .insets(horizontal: max(safeAreaInsets.leading, safeAreaInsets.trailing) + EdgeInsets.edgePadding)
            .proxy(collectionHStackProxy)
            .frame(height: 150)
            .onAppear {
                guard let currentChapter = chapters.first(where: { $0.secondsRange.contains(manager.seconds) }) else { return }
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
            AlternateLayoutView {
                Color.clear
            } content: {
                ImageView(chapter.imageSource)
                    .failure {
                        ZStack {
                            Rectangle()
                                .fill(Material.ultraThinMaterial)

                            SystemImageContentView(systemName: chapter.systemImage)
                                .background(color: Color.clear)
                        }
                    }
            }
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

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var activeSeconds: Duration = .zero

        let chapter: ChapterInfo.FullInfo
        let action: () -> Void

        private var isCurrentChapter: Bool {
            chapter.secondsRange.contains(activeSeconds)
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

        @State
        private var activeSeconds: Duration = .zero

        let chapter: ChapterInfo.FullInfo
        let action: () -> Void

        private var isCurrentChapter: Bool {
            chapter.secondsRange.contains(activeSeconds)
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

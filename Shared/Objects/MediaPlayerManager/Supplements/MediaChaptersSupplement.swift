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
import VLCUI

// TODO: current button
// TODO: scroll to current chapter on appear

struct MediaChaptersSupplement: MediaPlayerSupplement {

    let chapters: [ChapterInfo.FullInfo]
    let displayTitle: String = L10n.chapters
    let id: String = "Chapters"

    func chapter(for second: Duration) -> ChapterInfo.FullInfo? {
        chapters.first { $0.secondsRange.contains(second) }
    }

    func videoPlayerBody() -> some View {
        ChapterOverlay(chapters: chapters)
    }
}

extension MediaChaptersSupplement {

    private struct ChapterOverlay: View {

        @StateObject
        private var collectionHStackProxy: CollectionHStackProxy = .init()

        let chapters: [ChapterInfo.FullInfo]

//        var compact: some View {
//            CollectionVGrid(
//                uniqueElements: chapters,
//                layout: .columns(1, insets: .zero)
//            ) { chapter, _ in
//                HStack {
//                    ImageView(chapter.landscapeImageSources(maxWidth: 200))
//                        .failure {
//                            ZStack {
//                                Rectangle()
//                                    .fill(Material.ultraThinMaterial)
//
//                                SystemImageContentView(systemName: chapter.systemImage)
//                                    .background(color: Color.clear)
//                            }
//                        }
//                        .posterStyle(.landscape)
//
//                    VStack(alignment: .leading) {
//                        Text(chapter.chapterInfo.displayTitle)
//                            .lineLimit(1)
//                            .foregroundStyle(.white)
//                            .frame(height: 15)
//
//                        Text(chapter.chapterInfo.startSeconds ?? .zero, format: .runtime)
//                            .frame(height: 20)
//                            .foregroundStyle(Color(UIColor.systemBlue))
//                            .padding(.horizontal, 4)
//                            .background {
//                                Color(.darkGray)
//                                    .opacity(0.2)
//                                    .cornerRadius(4)
//                            }
//                    }
//                }
//                .frame(height: 100)
//            }
//        }

        var body: some View {
            CollectionHStack(
                uniqueElements: chapters
            ) { chapter in
                ChapterButton(chapter: chapter)
                    .frame(height: 150)
            }
            .insets(horizontal: .zero)
            .proxy(collectionHStackProxy)
            .frame(height: 150)
        }
    }

    struct ChapterButton: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var activeSeconds: Duration = .zero
        @State
        private var contentSize: CGSize = .zero

        let chapter: ChapterInfo.FullInfo

        var body: some View {
            Button {
                manager.proxy?.setSeconds(chapter.secondsRange.lowerBound)
            } label: {
                VStack(alignment: .leading, spacing: 5) {
                    AlternateLayoutView {
                        Color.clear
                    } content: {
                        ImageView(chapter.landscapeImageSources(maxWidth: 500))
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
                        if chapter.secondsRange.contains(activeSeconds) {
                            RoundedRectangle(cornerRadius: contentSize.width / 30)
                                .stroke(accentColor, lineWidth: 8)
                        }
                    }
                    .aspectRatio(1.77, contentMode: .fill)
                    .posterBorder()
                    .cornerRadius(ratio: 1 / 30, of: \.width)

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
                .font(.subheadline.weight(.semibold))
            }
            .trackingSize($contentSize)
            .onReceive(manager.secondsBox.$value) { newValue in
                activeSeconds = newValue
            }
        }
    }
}

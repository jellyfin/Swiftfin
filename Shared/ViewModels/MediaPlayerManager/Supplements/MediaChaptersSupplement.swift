//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import CollectionHStack
import Defaults
import JellyfinAPI
import SwiftUI
import VLCUI

// TODO: current button
// TODO: scroll to current chapter on appear

struct MediaChaptersSupplement: MediaPlayerSupplement {
    
    let title: String = "Chapters"
    let chapters: [ChapterInfo.FullInfo]
    
    func chapter(for second: TimeInterval) -> ChapterInfo.FullInfo? {
        chapters.first { $0.secondsRange.contains(second) }
    }

    func videoPlayerBody() -> some View {
        ChapterOverlay(chapters: chapters)
    }
}

struct ChapterOverlay: View {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.safeAreaInsets)
    @Binding
    private var safeAreaInsets

    @State
    private var contentSize: CGSize = .zero

    @StateObject
    private var collectionHStackProxy: CollectionHStackProxy<ChapterInfo.FullInfo> = .init()
    
    let chapters: [ChapterInfo.FullInfo]

    var body: some View {
        CollectionHStack(chapters) { chapter in
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
    
    @Environment(\.isSelected)
    private var isSelected: Bool
    
    @EnvironmentObject
    private var manager: MediaPlayerManager
    
    @State
    private var contentSize: CGSize = .zero

    let chapter: ChapterInfo.FullInfo
    
    var body: some View {
        Button {
//            manager.send(.seek(seconds: chapter.secondsRange.lowerBound))
            manager.proxy.setTime(chapter.secondsRange.lowerBound)
        } label: {
            VStack(alignment: .leading, spacing: 5) {
                ZStack {
                    Color.clear
                    
                    ImageView(chapter.landscapeImageSources(maxWidth: 500))
                        .failure {
                            SystemImageContentView(systemName: chapter.systemImage)
                        }
                }
                .overlay {
                    if chapter.secondsRange.contains(manager.seconds) {
                        RoundedRectangle(cornerRadius: contentSize.width / 30)
                            .stroke(accentColor, lineWidth: 8)
                    }
                }
                .aspectRatio(1.77, contentMode: .fill)
                .posterBorder(ratio: 1 / 30, of: \.width)
                .cornerRadius(ratio: 1 / 30, of: \.width)

                Text(chapter.chapterInfo.displayTitle)
                    .lineLimit(1)
                    .foregroundStyle(.white)
                    .frame(height: 15)

                Text(chapter.chapterInfo.startTimeSeconds, format: .runtime)
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
    }
}

//struct MediaChaptersSupplement_Previews: PreviewProvider {
//    static var previews: some View {
//        ChapterOverlay(chapters: [
//            .init(chapterInfo: .init(name: "Test", startPositionTicks: 0), imageSource: .init(), secondsRange: 0 ..< 100),
//            .init(chapterInfo: .init(name: "Test", startPositionTicks: 100), imageSource: .init(), secondsRange: 100 ..< 200),
//            .init(chapterInfo: .init(name: "Test", startPositionTicks: 200), imageSource: .init(), secondsRange: 200 ..< 301),
//            .init(chapterInfo: .init(name: "Test", startPositionTicks: 200), imageSource: .init(), secondsRange: 200 ..< 301),
//            .init(chapterInfo: .init(name: "Test", startPositionTicks: 200), imageSource: .init(), secondsRange: 200 ..< 303),
//        ])
//        .frame(height: 150)
//        .environment(\.safeAreaInsets, .constant(EdgeInsets.edgeInsets))
//        .environmentObject(
//            MediaPlayerManager(
//                playbackItem: .init(
//                    baseItem: .init(
//                        indexNumber: 1,
//                        name: "The Bear",
//                        parentIndexNumber: 1,
//                        runTimeTicks: 10_000_000_000,
//                        type: .episode
//                    ),
//                    mediaSource: .init(),
//                    playSessionID: "",
//                    url: URL(string: "/")!
//                )
//            )
//        )
//        .previewInterfaceOrientation(.landscapeRight)
//        .preferredColorScheme(.dark)
//    }
//}

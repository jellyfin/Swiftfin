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

// TODO: figure out why `continuousLeadingEdge` scroll behavior has different
//       insets than default continuous


//struct ChapterOverlay: View {
//
//    @Default(.accentColor)
//    private var accentColor
//
//    @Environment(\.safeAreaInsets)
//    @Binding
//    private var safeAreaInsets
//
//    @State
//    private var contentSize: CGSize = .zero
//
//    @StateObject
//    private var collectionHStackProxy: CollectionHStackProxy<ChapterInfo.FullInfo> = .init()
//    
//    let chapters: [ChapterInfo.FullInfo]
//
//    var body: some View {
//        CollectionHStack(chapters) { chapter in
//            ChapterButton(chapter: chapter)
//                .frame(height: 150)
//        }
//        .insets(horizontal: safeAreaInsets.leading)
//        .proxy(collectionHStackProxy)
//    }
//}
//
//struct ChapterButton: View {
//
//    @Default(.accentColor)
//    private var accentColor
//    
//    @Environment(\.isSelected)
//    private var isSelected: Bool
//
//    let chapter: ChapterInfo.FullInfo
//
//    var body: some View {
//        PosterButton(item: chapter, type: .landscape)
////            .content { EmptyView() }
//            .content {
//                VStack(alignment: .leading, spacing: 5) {
//                    
//                    Text(chapter.chapterInfo.displayTitle)
//                        .lineLimit(1)
//                        .foregroundStyle(.white)
//
//                    Text(chapter.chapterInfo.startTimeSeconds, format: .runtime)
//                        .foregroundStyle(Color(UIColor.systemBlue))
//                        .padding(.vertical, 2)
//                        .padding(.horizontal, 4)
//                        .background {
//                            Color(.darkGray)
//                                .opacity(0.2)
//                                .cornerRadius(4)
//                        }
//                }
//                .font(.subheadline.weight(.semibold))
//            }
//    }
//}
//            
////            Button {
////                let seconds = chapter.chapterInfo.startTimeSeconds
////                videoPlayerProxy.setTime(.seconds(seconds))
////
////                if videoPlayerManager.state != .playing {
////                    videoPlayerProxy.play()
////                }
////            } label: {
////                VStack(alignment: .leading) {
////                    ZStack {
////                        Color.black
////
////                        ImageView(chapter.landscapeImageSources(maxWidth: 500))
////                            .failure {
////                                SystemImageContentView(systemName: chapter.systemImage)
////                            }
////                            .aspectRatio(contentMode: .fit)
////                    }
////                    .overlay {
////                        modifier(OnSizeChangedModifier { size in
////                            if chapter.secondsRange.contains(currentProgressHandler.seconds) {
////                                RoundedRectangle(cornerRadius: size.width * (1 / 30))
////                                    .stroke(accentColor, lineWidth: 8)
////                                    .transition(.opacity.animation(.linear(duration: 0.1)))
////                                    .clipped()
////                            } else {
////                                RoundedRectangle(cornerRadius: size.width * (1 / 30))
////                                    .stroke(
////                                        .white.opacity(0.10),
////                                        lineWidth: 1.5
////                                    )
////                                    .clipped()
////                            }
////                        })
////                    }
////                    .aspectRatio(1.77, contentMode: .fill)
////                    .posterBorder(ratio: 1 / 30, of: \.width)
////                    .cornerRadius(ratio: 1 / 30, of: \.width)
////
////                    VStack(alignment: .leading, spacing: 5) {
////                        Text(chapter.chapterInfo.displayTitle)
////                            .font(.subheadline)
////                            .fontWeight(.semibold)
////                            .lineLimit(1)
////                            .foregroundColor(.white)
////
////                        Text(chapter.chapterInfo.timestampLabel)
////                            .font(.subheadline)
////                            .fontWeight(.semibold)
////                            .foregroundColor(Color(UIColor.systemBlue))
////                            .padding(.vertical, 2)
////                            .padding(.horizontal, 4)
////                            .background {
////                                Color(UIColor.darkGray).opacity(0.2).cornerRadius(4)
////                            }
////                    }
////                }
////            }
////            .buttonStyle(.plain)
////}

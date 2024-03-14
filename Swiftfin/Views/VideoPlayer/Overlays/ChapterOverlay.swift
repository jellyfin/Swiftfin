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

extension VideoPlayer.Overlay {

    struct ChapterOverlay: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType
        @Environment(\.safeAreaInsets)
        private var safeAreaInsets

        @EnvironmentObject
        private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @StateObject
        private var collectionHStackProxy: CollectionHStackProxy<ChapterInfo.FullInfo> = .init()

        var body: some View {
            VStack(spacing: 0) {

                Spacer(minLength: 0)
                    .allowsHitTesting(false)

                HStack {
                    L10n.chapters.text
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .accessibility(addTraits: [.isHeader])

                    Spacer()

                    Button {
                        if let currentChapter = viewModel.chapter(from: currentProgressHandler.seconds) {
                            let index = viewModel.chapters.firstIndex(of: currentChapter)!
                            collectionHStackProxy.scrollTo(index: index)
                        }
                    } label: {
                        Text(L10n.current)
                            .font(.title2)
                            .foregroundColor(accentColor)
                    }
                }
                .padding(.horizontal, safeAreaInsets.leading)
                .edgePadding(.horizontal)

                CollectionHStack(
                    viewModel.chapters,
                    minWidth: 200
                ) { chapter in
                    ChapterButton(chapter: chapter)
                }
                .insets(horizontal: EdgeInsets.defaultEdgePadding, vertical: EdgeInsets.defaultEdgePadding)
                .proxy(collectionHStackProxy)
                .onChange(of: currentOverlayType) { newValue in
                    guard newValue == .chapters else { return }

                    if let currentChapter = viewModel.chapter(from: currentProgressHandler.seconds) {
                        let index = viewModel.chapters.firstIndex(of: currentChapter)!
                        collectionHStackProxy.scrollTo(index: index, animated: false)
                    }
                }
            }
            .background {
                LinearGradient(
                    stops: [
                        .init(color: .clear, location: 0),
                        .init(color: .black.opacity(0.4), location: 0.4),
                        .init(color: .black.opacity(0.9), location: 1),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .allowsHitTesting(false)
            }
        }
    }
}

extension VideoPlayer.Overlay.ChapterOverlay {

    struct ChapterButton: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy

        let chapter: ChapterInfo.FullInfo

        var body: some View {
            Button {
                let seconds = chapter.chapterInfo.startTimeSeconds
                videoPlayerProxy.setTime(.seconds(seconds))

                if videoPlayerManager.state != .playing {
                    videoPlayerProxy.play()
                }
            } label: {
                VStack(alignment: .leading) {
                    ZStack {
                        Color.black

                        ImageView(chapter.landscapePosterImageSources(maxWidth: 500, single: false))
                            .failure {
                                SystemImageContentView(systemName: chapter.typeSystemImage)
                            }
                            .aspectRatio(contentMode: .fit)
                    }
                    .posterStyle(.landscape)
                    .overlay {
                        if chapter.secondsRange.contains(currentProgressHandler.seconds) {
                            RoundedRectangle(cornerRadius: 1)
                                .stroke(accentColor, lineWidth: 5)
                                .transition(.opacity.animation(.linear(duration: 0.1)))
                        }
                    }

                    VStack(alignment: .leading, spacing: 5) {
                        Text(chapter.chapterInfo.displayTitle)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .lineLimit(1)
                            .foregroundColor(.white)

                        Text(chapter.chapterInfo.timestampLabel)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(Color(UIColor.systemBlue))
                            .padding(.vertical, 2)
                            .padding(.horizontal, 4)
                            .background {
                                Color(UIColor.darkGray).opacity(0.2).cornerRadius(4)
                            }
                    }
                }
            }
            .buttonStyle(.plain)
        }
    }
}

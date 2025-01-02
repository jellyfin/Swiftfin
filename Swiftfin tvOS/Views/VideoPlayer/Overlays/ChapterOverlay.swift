//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI
import VLCUI

extension VideoPlayer {

    struct ChapterOverlay: View {

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType

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

        @State
        private var scrollViewProxy: ScrollViewProxy? = nil

        var body: some View {
            VStack {

                Spacer()

                HStack {

                    L10n.chapters.text
                        .font(.largeTitle)
                        .fontWeight(.bold)

                    Spacer()
                }
                .padding()
                .padding()

                ScrollViewReader { proxy in
                    ScrollView(.horizontal) {
                        HStack(alignment: .top) {
                            ForEach(viewModel.chapters, id: \.hashValue) { chapter in
                                PosterButton(
                                    item: chapter,
                                    type: .landscape
                                )
                                .imageOverlay {
                                    if chapter.secondsRange.contains(currentProgressHandler.seconds) {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(Color.jellyfinPurple, lineWidth: 8)
                                    }
                                }
                                .content {
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
                                .onSelect {
                                    let seconds = chapter.chapterInfo.startTimeSeconds
                                    videoPlayerProxy.setTime(.seconds(seconds))

                                    if videoPlayerManager.state != .playing {
                                        videoPlayerProxy.play()
                                    }
                                }
                            }
                        }
                        .padding()
                        .padding(.horizontal)
                    }
                    .onChange(of: currentOverlayType) { _, newValue in
                        guard newValue == .chapters else { return }
                        if let currentChapter = viewModel.chapter(from: currentProgressHandler.seconds) {
                            scrollViewProxy?.scrollTo(currentChapter.hashValue, anchor: .center)
                        }
                    }
                    .onAppear {
                        scrollViewProxy = proxy
                    }
                }
            }
        }
    }
}

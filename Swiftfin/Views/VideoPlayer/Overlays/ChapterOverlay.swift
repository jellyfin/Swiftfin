//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

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

        @State
        private var scrollViewProxy: ScrollViewProxy? = nil

        var body: some View {
            VStack {

                Spacer()
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
                            withAnimation {
                                scrollViewProxy?.scrollTo(currentChapter.hashValue, anchor: .center)
                            }
                        }
                    } label: {
                        Text("Current")
                            .font(.title2)
                            .foregroundColor(accentColor)
                    }
                }
                .padding(.leading, safeAreaInsets.leading)
                .padding(.trailing, safeAreaInsets.trailing)
                .if(UIDevice.isIPad) { view in
                    view.padding(.horizontal)
                }

                ScrollViewReader { proxy in
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .top, spacing: 15) {
                            ForEach(viewModel.chapters, id: \.hashValue) { chapter in
                                PosterButton(
                                    state: .item(chapter),
                                    type: .landscape
                                )
                                .imageOverlay { type in
                                    if case let PosterButtonType.item(info) = type,
                                       info.secondsRange.contains(currentProgressHandler.seconds)
                                    {
                                        RoundedRectangle(cornerRadius: 6)
                                            .stroke(accentColor, lineWidth: 8)
                                    }
                                }
                                .content { type in
                                    if case let PosterButtonType.item(info) = type {
                                        VStack(alignment: .leading, spacing: 5) {
                                            Text(info.chapterInfo.displayTitle)
                                                .font(.subheadline)
                                                .fontWeight(.semibold)
                                                .lineLimit(1)
                                                .foregroundColor(.white)

                                            Text(info.chapterInfo.timestampLabel)
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
                                .onSelect {
                                    let seconds = chapter.chapterInfo.startTimeSeconds
                                    videoPlayerProxy.setTime(.seconds(seconds))

                                    if videoPlayerManager.state != .playing {
                                        videoPlayerProxy.play()
                                    }
                                }
                            }
                        }
                        .padding(.leading, safeAreaInsets.leading)
                        .padding(.trailing, safeAreaInsets.trailing)
                        .padding(.bottom)
                        .if(UIDevice.isIPad) { view in
                            view.padding(.horizontal)
                        }
                    }
                    .onChange(of: currentOverlayType) { newValue in
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

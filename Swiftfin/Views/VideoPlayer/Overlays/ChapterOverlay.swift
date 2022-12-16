//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay {

    struct ChapterOverlay: View {

        @Default(.accentColor)
        private var accentColor

        @EnvironmentObject
        private var currentProgressHandler: CurrentProgressHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        var body: some View {
            VStack {
                Spacer()
                    .allowsHitTesting(false)

                ScrollViewReader { proxy in
                    PosterHStack(
                        title: L10n.chapters,
                        type: .landscape,
                        items: viewModel.chapters
                    )
                    .imageOverlay { type in
                        if case let PosterButtonType.item(info) = type, info.secondsRange.contains(currentProgressHandler.seconds) {
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
                    .trailing {
                        Button {
                            if let currentChapter = viewModel.chapters
                                .first(where: { $0.secondsRange.contains(currentProgressHandler.seconds) })
                            {
                                withAnimation {
                                    proxy.scrollTo(currentChapter.hashValue, anchor: .center)
                                }
                            }
                        } label: {
                            Text("Current")
                        }
                    }
                    .onSelect { info in
                        let seconds = info.chapterInfo.startTimeSeconds
                        videoPlayerProxy.setTime(.seconds(seconds))

                        if videoPlayerManager.state != .playing {
                            videoPlayerProxy.play()
                        }
                    }
                    .foregroundColor(.white)
                    .onAppear {
                        if let currentChapter = viewModel.chapters
                            .first(where: { $0.secondsRange.contains(currentProgressHandler.seconds) })
                        {
                            proxy.scrollTo(currentChapter.hashValue, anchor: .center)
                        }
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

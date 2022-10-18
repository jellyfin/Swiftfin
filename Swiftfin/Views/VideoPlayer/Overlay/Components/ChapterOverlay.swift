//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI
import VLCUI

extension ItemVideoPlayer.Overlay {

    struct ChapterOverlay: View {

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var secondsHandler: VideoPlayerManager.CurrentPlaybackInformation
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        var body: some View {
            VStack {
                Spacer()

                ScrollViewReader { proxy in
                    PosterHStack(
                        title: L10n.chapters,
                        type: .landscape,
                        items: viewModel.chapters
                    )
                    .imageOverlay { type in
                        if case let PosterButtonType.item(info) = type, info.secondsRange.contains(secondsHandler.currentSeconds) {
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.jellyfinPurple, lineWidth: 8)
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
                                .first(where: { $0.secondsRange.contains(secondsHandler.currentSeconds) })
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
                    }
                    .onAppear {
                        if let currentChapter = viewModel.chapters
                            .first(where: { $0.secondsRange.contains(secondsHandler.currentSeconds) })
                        {
                            proxy.scrollTo(currentChapter.hashValue, anchor: .center)
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
                }
            }
        }
    }
}

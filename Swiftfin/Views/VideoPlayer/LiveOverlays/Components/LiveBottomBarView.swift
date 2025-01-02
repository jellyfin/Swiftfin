//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI
import VLCUI

extension LiveVideoPlayer.Overlay {

    struct LiveBottomBarView: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider
        @Default(.VideoPlayer.jumpBackwardLength)
        private var jumpBackwardLength
        @Default(.VideoPlayer.jumpForwardLength)
        private var jumpForwardLength
        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType
        @Default(.VideoPlayer.Overlay.sliderType)
        private var sliderType
        @Default(.VideoPlayer.Overlay.timestampType)
        private var timestampType

        @Environment(\.currentOverlayType)
        @Binding
        private var currentOverlayType

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @EnvironmentObject
        private var currentProgressHandler: LiveVideoPlayerManager.CurrentProgressHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var videoPlayerManager: LiveVideoPlayerManager
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @State
        private var currentChapter: ChapterInfo.FullInfo?

        @ViewBuilder
        private var capsuleSlider: some View {
            CapsuleSlider(progress: $currentProgressHandler.scrubbedProgress)
                .isEditing(_isScrubbing.wrappedValue)
                .trackMask {
                    if chapterSlider && !viewModel.chapters.isEmpty {
                        VideoPlayer.Overlay.ChapterTrack()
                            .clipShape(Capsule())
                    } else {
                        Color.white
                    }
                }
                .bottomContent {
                    Group {
                        switch timestampType {
                        case .split:
                            VideoPlayer.Overlay.SplitTimeStamp()
                        case .compact:
                            VideoPlayer.Overlay.CompactTimeStamp()
                        }
                    }
                    .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        VideoPlayer.Overlay.SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
                .frame(height: 50)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(progress: $currentProgressHandler.scrubbedProgress)
                .isEditing(_isScrubbing.wrappedValue)
                .trackMask {
                    if chapterSlider && !viewModel.chapters.isEmpty {
                        VideoPlayer.Overlay.ChapterTrack()
                            .clipShape(Capsule())
                    } else {
                        Color.white
                    }
                }
                .bottomContent {
                    Group {
                        switch timestampType {
                        case .split:
                            VideoPlayer.Overlay.SplitTimeStamp()
                        case .compact:
                            VideoPlayer.Overlay.CompactTimeStamp()
                        }
                    }
                    .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        VideoPlayer.Overlay.SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
        }

        var body: some View {
            VStack(spacing: 0) {
                HStack {
                    if chapterSlider, let currentChapter {
                        Button {
                            currentOverlayType = .chapters
                            overlayTimer.stop()
                        } label: {
                            HStack {
                                Text(currentChapter.displayTitle)
                                    .monospacedDigit()

                                Image(systemName: "chevron.right")
                            }
                            .foregroundColor(.white)
                            .font(.subheadline.weight(.medium))
                        }
                        .disabled(isScrubbing)
                    }

                    Spacer()
                }
                .padding(.leading, 5)
                .padding(.bottom, 15)

                Group {
                    switch sliderType {
                    case .capsule: capsuleSlider
                    case .thumb: thumbSlider
                    }
                }
            }
            .onChange(of: currentProgressHandler.scrubbedSeconds) { newValue in
                guard chapterSlider else { return }
                let newChapter = viewModel.chapter(from: newValue)
                if newChapter != currentChapter {
                    if isScrubbing {
                        UIDevice.impact(.light)
                    }

                    self.currentChapter = newChapter
                }
            }
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Sliders
import SwiftUI
import VLCUI

extension ItemVideoPlayer.Overlay {

    struct BottomBarView: View {

        @Default(.VideoPlayer.Overlay.chapterSlider)
        private var chapterSlider
        @Default(.videoPlayerJumpBackward)
        private var jumpBackwardLength
        @Default(.videoPlayerJumpBackward)
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
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @EnvironmentObject
        private var currentProgressHandler: CurrentProgressHandler
        
        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @State
        private var scrubbingRate: CGFloat = 1

        @ViewBuilder
        private var capsuleSlider: some View {
            CapsuleSlider(progress: $currentProgressHandler.scrubbedProgress)
                .rate($scrubbingRate)
                .trackMask {
                    if chapterSlider {
                        ChapterTrack()
                            .clipShape(Capsule())
                    } else {
                        Color.white
                    }
                }
                .bottomContent {
                    Group {
                        switch timestampType {
                        case .split:
                            SplitTimeStamp()
                        case .compact:
                            CompactTimeStamp()
                        }
                    }
                    .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
                .onEditingChanged { isEditing in
                    isScrubbing = isEditing
                    scrubbingRate = 1
                }
                .frame(height: 50)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(progress: $currentProgressHandler.scrubbedProgress)
                .rate($scrubbingRate)
                .trackMask {
                    if chapterSlider {
                        ChapterTrack()
                            .clipShape(Capsule())
                    } else {
                        Color.white
                    }
                }
                .bottomContent {
                    Group {
                        switch timestampType {
                        case .split:
                            SplitTimeStamp()
                        case .compact:
                            CompactTimeStamp()
                        }
                    }
                    .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
                .onEditingChanged { isEditing in
                    isScrubbing = isEditing
                    scrubbingRate = 1
                }
        }

        var body: some View {
            VStack(spacing: 0) {
                if chapterSlider && !viewModel.chapters.isEmpty {
                    HStack {
                        if let currentChapter = viewModel.chapter(from: currentProgressHandler.scrubbedSeconds) {
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
                }
                
                Group {
                    switch sliderType {
                    case .capsule: capsuleSlider
                    case .thumb: thumbSlider
                    }
                }
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.linear(duration: 0.1), value: scrubbingRate)
        }
    }
}

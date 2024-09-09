//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay {

    struct BottomBarView: View {

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

        @Environment(\.isPresentingOverlay)
        @Binding
        private var isPresentingOverlay
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @EnvironmentObject
        private var overlayTimer: DelayIntervalTimer
        @EnvironmentObject
        private var manager: VideoPlayerManager

        @EnvironmentObject
        private var scrubbedProgress: ProgressBox

        @State
        private var currentChapter: ChapterInfo.FullInfo?
        @State
        private var pulse = false

        @ViewBuilder
        private var capsuleSlider: some View {
            CapsuleSlider(progress: $scrubbedProgress.progress)
                .isEditing(_isScrubbing.wrappedValue)
//                .trackMask {
//                    if chapterSlider && viewModel.chapters.isNotEmpty {
//                        ChapterTrack()
//                            .clipShape(Capsule())
//                    } else {
//                        Color.white
//                    }
//                }
                .bottomContent {
                    SplitTimeStamp()
                        .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
                .frame(height: 50)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(progress: $scrubbedProgress.progress)
                .isEditing(_isScrubbing.wrappedValue)
                .trackMask {
//                    if chapterSlider && viewModel.chapters.isNotEmpty {
//                        ChapterTrack()
//                            .clipShape(Capsule())
//                    } else {
//                        Color.white
//                    }
                }
                .bottomContent {
                    SplitTimeStamp()
                        .padding(5)
                }
                .leadingContent {
                    if playbackButtonType == .compact {
                        SmallPlaybackButtons()
                            .padding(.trailing)
                            .disabled(isScrubbing)
                    }
                }
        }

        var body: some View {
            VStack(spacing: 0) {

                Group {
                    switch sliderType {
                    case .capsule: capsuleSlider
                    case .thumb: thumbSlider
                    }
                }
                .disabled(manager.state == .loadingItem)
//                .debugBackground(.blue)
//                .pulse($pulse)
            }
//            .onChange(of: manager.state) { newValue in
//                pulse = newValue == .loadingItem
//            }
        }
    }
}

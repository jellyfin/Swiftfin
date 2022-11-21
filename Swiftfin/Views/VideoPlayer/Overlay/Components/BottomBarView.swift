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
        @Environment(\.scrubbedProgress)
        @Binding
        private var scrubbedProgress: CGFloat

        @EnvironmentObject
        private var currentSecondsHandler: VideoPlayerManager.CurrentPlaybackInformation
        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @State
        private var currentSeconds: Int = 0
        @State
        private var progress: CGFloat = 0
        @State
        private var scrubbingRate: CGFloat = 1
        @State
        private var negativeScrubbing: Bool = true

        private var trailingTimeStamp: String {
            if negativeScrubbing {
                return Double(viewModel.item.runTimeSeconds - currentSeconds)
                    .timeLabel
                    .prepending("-")
            } else {
                return Double(viewModel.item.runTimeSeconds)
                    .timeLabel
            }
        }

        @ViewBuilder
        private var capsuleSlider: some View {
            CapsuleSlider(progress: $progress)
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
                            SplitTimeStamp(currentSeconds: $currentSeconds)
                        case .compact:
                            CompactTimeStamp(currentSeconds: $currentSeconds)
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
            ThumbSlider(progress: $progress)
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
                            SplitTimeStamp(currentSeconds: $currentSeconds)
                        case .compact:
                            CompactTimeStamp(currentSeconds: $currentSeconds)
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
                        if let currentChapter = viewModel.chapter(from: progress) {
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
            .onChange(of: currentSecondsHandler.currentSeconds) { newValue in
                guard !isScrubbing else { return }
                self.currentSeconds = newValue
                self.progress = CGFloat(newValue) / CGFloat(viewModel.item.runTimeSeconds)
            }
            .onChange(of: isScrubbing) { newValue in

                if newValue {
                    overlayTimer.stop()
                } else {
                    overlayTimer.start(5)
                }

                guard !newValue else { return }
                let scrubbedSeconds = Int(CGFloat(viewModel.item.runTimeSeconds) * progress)
                videoPlayerProxy.setTime(.seconds(scrubbedSeconds))
            }
            .onChange(of: progress) { _ in
                guard isScrubbing else { return }
                let scrubbedSeconds = Int(CGFloat(viewModel.item.runTimeSeconds) * progress)
                self.currentSeconds = scrubbedSeconds

                scrubbedProgress = progress
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
            .animation(.linear(duration: 0.1), value: scrubbingRate)
            .onAppear {
                currentSeconds = currentSecondsHandler.currentSeconds
                progress = CGFloat(currentSecondsHandler.currentSeconds) / CGFloat(viewModel.item.runTimeSeconds)
            }
        }
    }
}

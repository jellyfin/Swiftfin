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
        @Environment(\.scrubbingProgress)
        @Binding
        private var scrubbedProgress: ProgressBox

        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var manager: VideoPlayerManager

        @State
        private var currentChapter: ChapterInfo.FullInfo?
        @State
        private var pulse = false

        @ViewBuilder
        private var capsuleSlider: some View {
            CapsuleSlider(progress: _scrubbedProgress.wrappedValue.progress)
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
                .frame(height: 50)
        }

        @ViewBuilder
        private var thumbSlider: some View {
            ThumbSlider(progress: _scrubbedProgress.wrappedValue.progress)
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
                .disabled(manager.state == .loadingItem)
                .pulse($pulse)
            }
            .onChange(of: manager.state) { newValue in
                pulse = newValue == .loadingItem
            }
//            .onChange(of: currentProgressHandler.scrubbedSeconds) { newValue in
//                guard chapterSlider else { return }
//                let newChapter = viewModel.chapter(from: newValue)
//                if newChapter != currentChapter {
//                    if isScrubbing {
//                        UIDevice.impact(.light)
//                    }
//
//                    self.currentChapter = newChapter
//                }
//            }
        }
    }
}

extension View {

    func pulse(_ isPulsing: Binding<Bool> = .constant(true)) -> some View {
        modifier(PulsingModifier(isPulsing: isPulsing))
    }
}

struct PulsingModifier: ViewModifier {

    @Binding
    private var isPulsing: Bool

    @State
    private var active: Bool = false

    private let range: ClosedRange<Double> = 0.5 ... 1.0
    private let duration: TimeInterval = 1.0

    init(isPulsing: Binding<Bool> = .constant(true)) {
        self._isPulsing = isPulsing
    }

    func body(content: Content) -> some View {
        content
            .mask {
                Color.white
                    .opacity(active ? range.lowerBound : range.upperBound)
                    .animation(.easeInOut(duration: duration).repeatForever(autoreverses: true), value: active)
                    .onChange(of: isPulsing) { _ in
                        useTransaction()
                    }
            }
    }

    private func useTransaction() {
        var transaction = Transaction()
        transaction.disablesAnimations = active

        withTransaction(transaction) {
            withAnimation {
                active.toggle()
            }
        }
    }
}

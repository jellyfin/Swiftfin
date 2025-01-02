//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.Overlay {

    struct BottomBarView: View {

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
        private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy
        @EnvironmentObject
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @FocusState
        private var isBarFocused: Bool

        @ViewBuilder
        private var playbackStateView: some View {
            if videoPlayerManager.state == .playing {
                Image(systemName: "pause.circle")
            } else if videoPlayerManager.state == .paused {
                Image(systemName: "play.circle")
            } else {
                ProgressView()
            }
        }

        var body: some View {
            VStack(alignment: .VideoPlayerTitleAlignmentGuide, spacing: 10) {

                if let subtitle = viewModel.item.subtitle {
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .alignmentGuide(.VideoPlayerTitleAlignmentGuide) { dimensions in
                            dimensions[.leading]
                        }
                }

                HStack {

                    Text(viewModel.item.displayTitle)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .alignmentGuide(.VideoPlayerTitleAlignmentGuide) { dimensions in
                            dimensions[.leading]
                        }

                    Spacer()

                    BarActionButtons()
                }

                tvOSSliderView(value: $currentProgressHandler.scrubbedProgress)
                    .onEditingChanged { isEditing in
                        isScrubbing = isEditing

                        if isEditing {
                            overlayTimer.pause()
                        } else {
                            overlayTimer.start(5)
                        }
                    }
                    .focused($isBarFocused)
                    .frame(height: 60)
//                    .visible(isScrubbing || isPresentingOverlay)

                HStack(spacing: 15) {

                    Text(currentProgressHandler.scrubbedSeconds.timeLabel)
                        .monospacedDigit()
                        .foregroundColor(.white)

                    playbackStateView
                        .frame(maxWidth: 40, maxHeight: 40)

                    Spacer()

                    Text((viewModel.item.runTimeSeconds - currentProgressHandler.scrubbedSeconds).timeLabel.prepending("-"))
                        .monospacedDigit()
                        .foregroundColor(.white)
                }
            }
            .onChange(of: isPresentingOverlay) { _, newValue in
                guard newValue else { return }
            }
        }
    }
}

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

extension ItemVideoPlayer.Overlay {

    struct BottomBarView: View {

        @Default(.videoPlayerJumpBackward)
        private var jumpBackwardLength
        @Default(.videoPlayerJumpBackward)
        private var jumpForwardLength
        @Default(.VideoPlayer.Overlay.playbackButtonType)
        private var playbackButtonType
        @Default(.VideoPlayer.Overlay.timestampType)
        private var timestampType

        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel
        @EnvironmentObject
        private var currentSecondsHandler: CurrentSecondsHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @State
        private var currentSeconds: Int = 0
        @State
        private var progress: CGFloat = 0
        @State
        private var scrubbingRate: CGFloat = 1
        @State
        private var negativeScrubbing: Bool = true

        init() {
            print("bottom bar init-ed")
        }

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

        var body: some View {
            CapsuleSlider(progress: $progress)
                .rate($scrubbingRate)
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
                            .frame(height: 50)
                            .padding(.trailing)
                    }
                }
                .onEditingChanged { isEditing in
                    isScrubbing = isEditing
                    scrubbingRate = 1
                }
                .padding()
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
                    let scrubbedSeconds = Int32(CGFloat(viewModel.item.runTimeSeconds) * progress)
                    viewModel.proxy.setTime(.seconds(Int32(scrubbedSeconds)))
                }
                .onChange(of: progress) { _ in
                    guard isScrubbing else { return }
                    let scrubbedSeconds = Int(CGFloat(viewModel.item.runTimeSeconds) * progress)
                    self.currentSeconds = scrubbedSeconds
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

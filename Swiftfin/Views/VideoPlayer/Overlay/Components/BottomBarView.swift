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

        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel
        @EnvironmentObject
        private var currentSecondsHandler: CurrentSecondsHandler
        @EnvironmentObject
        private var overlayTimer: TimerProxy

        @State
        private var currentSeconds: Int = 0
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @State
        private var progress: CGFloat = 0
        @State
        private var scrubbingRate: CGFloat = 1

        init() {
            print("bottom bar init-ed")
        }

        var body: some View {
            CapsuleSlider(progress: $progress)
                .rate($scrubbingRate)
                .topContent {
                    HStack {
                        Text(viewModel.item.displayName)
                            .font(.title3)
                            .fontWeight(.bold)

                        Spacer()
                    }
                    .padding(.bottom, 5)
                }
                .bottomContent {
                    ZStack {
                        HStack {
                            Text(Double(currentSeconds).timeLabel)
                                .monospacedDigit()
                            
                            if isScrubbing {
                                Text(Double(currentSecondsHandler.currentSeconds).timeLabel)
                                    .monospacedDigit()
                                    .transition(.opacity)
                                    .foregroundColor(.gray)
                            }
                            
                            Spacer()
                            
                            Text(Double(viewModel.item.runTimeSeconds - currentSeconds).timeLabel)
                                .monospacedDigit()
                        }
                        
                        if scrubbingRate < 1 {
                            Text("Hi-Speed Scrubbing")
                                .frame(maxWidth: .infinity)
                                .transition(.opacity)
                        }
                    }
                    .font(.caption)
                    .padding(5)
                }
                .onEditingChanged { isEditing in
                    isScrubbing = isEditing
                    scrubbingRate = 1
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
        }
    }
}

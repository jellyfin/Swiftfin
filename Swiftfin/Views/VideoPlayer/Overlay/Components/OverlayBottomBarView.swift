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
        
        @ObservedObject
        var viewModel: ItemVideoPlayerViewModel
        
        @State
        private var currentSeconds: Int = 0
        @State
        private var isScrubbing: Bool = false
        
        @ViewBuilder
        private var valueTrackView: some View {
            ZStack {
                Color.clear
                
                Capsule()
                    .foregroundColor(.jellyfinPurple)
                    .frame(height: isScrubbing ? 20 : 10)
            }
        }
        
        @ViewBuilder
        private var valueTrack: some View {
            HorizontalValueTrack(view: valueTrackView)
                .background {
                    Capsule()
                        .foregroundColor(Color.gray)
                        .opacity(0.5)
                        .frame(height: isScrubbing ? 20 : 10)
                }
                .contentShape(Rectangle())
        }
        
        var body: some View {
            HStack {
                HStack(spacing: 20) {
                    Button {
                        viewModel.eventSubject.send(.jumpBackward(jumpBackwardLength.rawValue))
                    } label: {
                        Image(systemName: jumpBackwardLength.backwardImageLabel)
                            .font(.system(size: 24, weight: .heavy, design: .default))
                    }

                    Button {
                        switch viewModel.state {
                        case .playing:
                            viewModel.eventSubject.send(.pause)
                        default:
                            viewModel.eventSubject.send(.play)
                        }
                    } label: {
                        Group {
                            switch viewModel.state {
                            case .stopped, .paused:
                                Image(systemName: "play.fill")
                            case .playing:
                                Image(systemName: "pause")
                            default:
                                ProgressView()
                            }
                        }
                        .font(.system(size: 28, weight: .heavy, design: .default))
                    }

                    Button {
                        viewModel.eventSubject.send(.jumpForward(jumpForwardLength.rawValue))
                    } label: {
                        Image(systemName: jumpForwardLength.forwardImageLabel)
                            .font(.system(size: 24, weight: .heavy, design: .default))
                    }
                }
                .tint(Color.white)
                .foregroundColor(Color.white)
                
                Text(Double(currentSeconds).timeLabel)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .frame(minWidth: 70, maxWidth: 70)
                
                ValueSlider(value: $currentSeconds,
                            in: 0...viewModel.item.runTimeSeconds,
                            step: 1) { isEditing in
                    isScrubbing = isEditing
                }
                .valueSliderStyle(HorizontalValueSliderStyle.init(
                    track: valueTrack,
                    thumbSize: .zero,
                    thumbInteractiveSize: CGSize.Circle(radius: 100),
                    options: .interactiveTrack))
                
                Text(Double(viewModel.item.runTimeSeconds - currentSeconds).timeLabel)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .frame(minWidth: 70, maxWidth: 70)
            }
            .onChange(of: viewModel.currentSeconds, perform: { newValue in
                guard !isScrubbing else { return }
                self.currentSeconds = newValue
            })
            .onChange(of: isScrubbing) { newValue in
                guard !newValue else { return }
                viewModel.eventSubject.send(.setTime(.seconds(Int32(currentSeconds))))
            }
            .onAppear {
                self.currentSeconds = viewModel.item.startTimeSeconds
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
        }
    }
}

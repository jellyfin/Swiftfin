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
        private var viewModel: ItemVideoPlayerViewModel
        
        @State
        private var currentSeconds: Int
        @State
        private var isScrubbing: Bool = false
        @State
        private var progress: CGFloat
        
        init(viewModel: ItemVideoPlayerViewModel) {
            self.viewModel = viewModel
            
            self.currentSeconds = viewModel.currentSeconds
            self.progress = CGFloat(viewModel.currentSeconds) / CGFloat(viewModel.item.runTimeSeconds)
            
            print("bottom bar init-ed")
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
                
                CapsuleSlider(progress: $progress)
                    .onEditingChanged { isEditing in
                        isScrubbing = isEditing
                    }
                
                Text(Double(viewModel.item.runTimeSeconds - currentSeconds).timeLabel)
                    .font(.system(size: 18, weight: .semibold, design: .default))
                    .frame(minWidth: 70, maxWidth: 70)
            }
            .onChange(of: viewModel.currentSeconds, perform: { newValue in
                guard !isScrubbing else { return }
                self.currentSeconds = newValue
                self.progress = CGFloat(newValue) / CGFloat(viewModel.item.runTimeSeconds)
            })
            .onChange(of: isScrubbing) { newValue in
                guard !newValue else { return }
                let scrubbedSeconds = Int32(CGFloat(viewModel.item.runTimeSeconds) * progress)
                viewModel.eventSubject.send(.setTime(.seconds(Int32(scrubbedSeconds))))
            }
            .onChange(of: progress){ newValue in
                guard isScrubbing else { return }
                let scrubbedSeconds = Int(CGFloat(viewModel.item.runTimeSeconds) * progress)
                self.currentSeconds = scrubbedSeconds
            }
            .animation(.linear(duration: 0.1), value: isScrubbing)
        }
    }
}

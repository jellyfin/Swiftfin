//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

extension ItemVideoPlayer.Overlay {
    
    struct SmallPlaybackButtons: View {
        
        @Default(.videoPlayerJumpBackward)
        private var jumpBackwardLength
        @Default(.videoPlayerJumpBackward)
        private var jumpForwardLength
        
        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel
        
        var body: some View {
            HStack(spacing: 20) {
                Button {
                    viewModel.proxy.jumpBackward(jumpBackwardLength.rawValue)
                } label: {
                    Image(systemName: jumpBackwardLength.backwardImageLabel)
                        .font(.system(size: 24, weight: .heavy, design: .default))
                }

                Button {
                    switch viewModel.state {
                    case .playing:
                        viewModel.proxy.pause()
                    default:
                        viewModel.proxy.play()
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
                    viewModel.proxy.jumpForward(jumpForwardLength.rawValue)
                } label: {
                    Image(systemName: jumpForwardLength.forwardImageLabel)
                        .font(.system(size: 24, weight: .heavy, design: .default))
                }
            }
            .tint(Color.white)
            .foregroundColor(Color.white)
        }
    }
    
    struct LargePlaybackButtons: View {
        
        @Default(.videoPlayerJumpBackward)
        private var jumpBackwardLength
        @Default(.videoPlayerJumpBackward)
        private var jumpForwardLength
        
        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel
        
        var body: some View {
            HStack(spacing: 70) {
                Button {
                    viewModel.proxy.jumpBackward(jumpBackwardLength.rawValue)
                } label: {
                    Image(systemName: jumpBackwardLength.backwardImageLabel)
                        .font(.system(size: 36, weight: .bold, design: .default))
                }

                Button {
                    switch viewModel.state {
                    case .playing:
                        viewModel.proxy.pause()
                    default:
                        viewModel.proxy.play()
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
                                .scaleEffect(2)
                        }
                    }
                    .font(.system(size: 56, weight: .bold, design: .default))
                }
                .frame(width: 100)

                Button {
                    viewModel.proxy.jumpForward(jumpForwardLength.rawValue)
                } label: {
                    Image(systemName: jumpForwardLength.forwardImageLabel)
                        .font(.system(size: 36, weight: .bold, design: .default))
                }
            }
            .tint(Color.white)
            .foregroundColor(Color.white)
        }
    }
}

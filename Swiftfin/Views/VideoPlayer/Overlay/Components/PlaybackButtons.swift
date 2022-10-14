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
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy

        var body: some View {
            HStack(spacing: 15) {
                Button {
                    videoPlayerProxy.jumpBackward(Int(jumpBackwardLength.rawValue))
                } label: {
                    Image(systemName: jumpBackwardLength.backwardImageLabel)
                        .font(.system(size: 24, weight: .heavy, design: .default))
                }

                Button {
                    switch videoPlayerManager.state {
                    case .playing:
                        videoPlayerProxy.pause()
                    default:
                        videoPlayerProxy.play()
                    }
                } label: {
                    Group {
                        switch videoPlayerManager.state {
                        case .stopped, .paused:
                            Image(systemName: "play.fill")
                        case .playing:
                            Image(systemName: "pause")
                        default:
                            ProgressView()
                        }
                    }
                    .font(.system(size: 28, weight: .heavy, design: .default))
                    .frame(width: 50)
                    .contentShape(Rectangle())
                }

                Button {
                    videoPlayerProxy.jumpForward(Int(jumpForwardLength.rawValue))
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
        private var videoPlayerManager: VideoPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy

        @State
        private var deviceOrientation: UIDeviceOrientation = UIDevice.current.orientation

        var body: some View {
            HStack(spacing: 0) {
                Button {
                    videoPlayerProxy.jumpBackward(Int(jumpBackwardLength.rawValue))
                } label: {
                    Image(systemName: jumpBackwardLength.backwardImageLabel)
                        .font(.system(size: 36, weight: .regular, design: .default))
                }

                Button {
                    switch videoPlayerManager.state {
                    case .playing:
                        videoPlayerProxy.pause()
                    default:
                        videoPlayerProxy.play()
                    }
                } label: {
                    Group {
                        switch videoPlayerManager.state {
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
                .frame(maxWidth: 300)

                Button {
                    videoPlayerProxy.jumpForward(Int(jumpForwardLength.rawValue))
                } label: {
                    Image(systemName: jumpForwardLength.forwardImageLabel)
                        .font(.system(size: 36, weight: .regular, design: .default))
                }
            }
            .tint(Color.white)
            .foregroundColor(Color.white)
            .detectOrientation($deviceOrientation)
        }
    }
}

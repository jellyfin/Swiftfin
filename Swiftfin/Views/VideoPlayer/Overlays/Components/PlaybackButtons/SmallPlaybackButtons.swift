//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import VLCUI

extension VideoPlayer.Overlay {

    struct SmallPlaybackButtons: View {

        @Default(.VideoPlayer.jumpBackwardLength)
        private var jumpBackwardLength
        @Default(.VideoPlayer.jumpForwardLength)
        private var jumpForwardLength
        @Default(.VideoPlayer.showJumpButtons)
        private var showJumpButtons

        @EnvironmentObject
        private var timerProxy: DelayIntervalTimer
        @EnvironmentObject
        private var videoPlayerManager: MediaPlayerManager
        @EnvironmentObject
        private var videoPlayerProxy: VLCVideoPlayer.Proxy

        @ViewBuilder
        private var jumpBackwardButton: some View {
            Button {
                videoPlayerProxy.jumpBackward(Int(jumpBackwardLength.rawValue))
                timerProxy.delay(interval: 5)
            } label: {
                Image(systemName: jumpBackwardLength.backwardSystemImage)
                    .font(.system(size: 24, weight: .bold, design: .default))
            }
            .contentShape(Rectangle())
        }

        @ViewBuilder
        private var playButton: some View {
            Button {
                switch videoPlayerManager.state {
                case .playing:
                    videoPlayerProxy.pause()
                default:
                    videoPlayerProxy.play()
                }
                timerProxy.delay(interval: 5)
            } label: {
                Group {
                    switch videoPlayerManager.state {
                    case .paused:
                        Image(systemName: "play.fill")
                    case .playing:
                        Image(systemName: "pause.fill")
                    default:
                        ProgressView()
                    }
                }
                .font(.system(size: 28, weight: .bold, design: .default))
                .frame(width: 50, height: 50)
            }
            .contentShape(Rectangle())
        }

        @ViewBuilder
        private var jumpForwardButton: some View {
            Button {
                videoPlayerProxy.jumpForward(Int(jumpForwardLength.rawValue))
                timerProxy.delay(interval: 5)
            } label: {
                Image(systemName: jumpForwardLength.forwardSystemImage)
                    .font(.system(size: 24, weight: .bold, design: .default))
            }
            .contentShape(Rectangle())
        }

        var body: some View {
            HStack(spacing: 15) {

                if showJumpButtons {
                    jumpBackwardButton
                }

                playButton

                if showJumpButtons {
                    jumpForwardButton
                }
            }
            .tint(Color.white)
            .foregroundColor(Color.white)
        }
    }
}

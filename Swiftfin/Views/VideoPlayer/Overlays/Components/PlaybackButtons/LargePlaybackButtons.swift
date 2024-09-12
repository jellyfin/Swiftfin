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

    struct LargePlaybackButtons: View {

        @Default(.VideoPlayer.jumpBackwardLength)
        private var jumpBackwardLength
        @Default(.VideoPlayer.jumpForwardLength)
        private var jumpForwardLength
        @Default(.VideoPlayer.showJumpButtons)
        private var showJumpButtons

        @EnvironmentObject
        private var overlayTimer: DelayIntervalTimer
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ViewBuilder
        private var playButton: some View {
            Button(
                manager.playbackRequestState.displayTitle,
                systemImage: manager.playbackRequestState.systemImage
            ) {
                switch manager.playbackRequestState {
                case .play:
                    manager.send(.pause)
                case .pause:
                    manager.send(.play)
                }
            }
            .transition(.opacity.combined(with: .scale).animation(.bouncy))
            .font(.system(size: 56, weight: .bold, design: .default))
            .contentShape(Rectangle())
            .labelStyle(.iconOnly)
            .id(manager.playbackRequestState)
        }

        @ViewBuilder
        private var jumpForwardButton: some View {
            Button {
//                manager.proxy.jumpForward(jumpForwardLength.rawValue)
            } label: {
                Label(
                    jumpForwardLength.displayTitle,
                    systemImage: jumpForwardLength.forwardSystemImage
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 36, weight: .regular, design: .default))
                .padding(10)
            }
            .foregroundStyle(.primary)
        }

        @ViewBuilder
        private var jumpBackwardButton: some View {
            Button {
//                manager.proxy.jumpBackward(jumpBackwardLength.rawValue)
            } label: {
                Label(
                    jumpBackwardLength.displayTitle,
                    systemImage: jumpBackwardLength.backwardSystemImage
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 36, weight: .regular, design: .default))
                .padding(10)
            }
            .foregroundStyle(.primary)
        }

        var body: some View {
            HStack(spacing: 0) {
                if showJumpButtons {
                    jumpBackwardButton
                }

                playButton
                    .frame(minWidth: 100, maxWidth: 300)

                if showJumpButtons {
                    jumpForwardButton
                }
            }
            .buttonStyle(.videoPlayerBarButton { isPressed in
                if isPressed {
                    overlayTimer.stop()
                } else {
                    overlayTimer.delay()
                }
            })
        }
    }
}

struct BounceButtonStyle: ButtonStyle {

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.9 : 1)
            .animation(.bouncy, value: configuration.isPressed)
    }
}

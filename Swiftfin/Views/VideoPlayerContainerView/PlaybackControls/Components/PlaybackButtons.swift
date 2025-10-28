//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: adjust button sizes/padding on compact/regular?
// TODO: jump rotation symbol effects

extension VideoPlayer.PlaybackControls {

    struct PlaybackButtons: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private func onPressed(isPressed: Bool) {
            if isPressed {
                containerState.timer.stop()
            } else {
                containerState.timer.poke()
            }
        }

        private var shouldShowJumpButtons: Bool {
            !manager.item.isLiveStream
        }

        @ViewBuilder
        private var playButton: some View {
            Button {
                switch manager.playbackRequestStatus {
                case .playing:
                    manager.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    manager.setPlaybackRequestStatus(status: .playing)
                }
            } label: {
                Group {
                    switch manager.playbackRequestStatus {
                    case .playing:
                        Label("Pause", systemImage: "pause.fill")
                    case .paused:
                        Label(L10n.play, systemImage: "play.fill")
                    }
                }
                .transition(.opacity.combined(with: .scale).animation(.bouncy(duration: 0.7, extraBounce: 0.2)))
                .font(.system(size: 36, weight: .bold, design: .default))
                .contentShape(Rectangle())
                .labelStyle(.iconOnly)
                .padding(20)
            }
        }

        @ViewBuilder
        private var jumpForwardButton: some View {
            Button {
                manager.proxy?.jumpForward(jumpForwardInterval.rawValue)
            } label: {
                Label(
                    "\(jumpForwardInterval.rawValue, format: Duration.UnitsFormatStyle(allowedUnits: [.seconds], width: .narrow))",
                    systemImage: jumpForwardInterval.forwardSystemImage
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 32, weight: .regular, design: .default))
                .padding(10)
            }
            .foregroundStyle(.primary)
        }

        @ViewBuilder
        private var jumpBackwardButton: some View {
            Button {
                manager.proxy?.jumpBackward(jumpBackwardInterval.rawValue)
            } label: {
                Label(
                    "\(jumpBackwardInterval.rawValue, format: Duration.UnitsFormatStyle(allowedUnits: [.seconds], width: .narrow))",
                    systemImage: jumpBackwardInterval.backwardSystemImage
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 32, weight: .regular, design: .default))
                .padding(10)
            }
            .foregroundStyle(.primary)
        }

        var body: some View {
            HStack(spacing: 0) {
                if shouldShowJumpButtons {
                    jumpBackwardButton
                }

                playButton
                    .frame(minWidth: 50, maxWidth: 150)

                if shouldShowJumpButtons {
                    jumpForwardButton
                }
            }
            .buttonStyle(OverlayButtonStyle(onPressed: onPressed))
            .padding(.horizontal, 50)
        }
    }
}

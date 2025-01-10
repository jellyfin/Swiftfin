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

    struct PlaybackButtons: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval
        @Default(.VideoPlayer.showJumpButtons)
        private var showJumpButtons

        @EnvironmentObject
        private var overlayTimer: PokeIntervalTimer
        @EnvironmentObject
        private var manager: MediaPlayerManager

        private func onPressed(isPressed: Bool) {
            if isPressed {
                overlayTimer.stop()
            } else {
                overlayTimer.poke()
            }
        }

        private var shouldShowJumpButtons: Bool {
            showJumpButtons && !manager.item.isLiveStream
        }

        @ViewBuilder
        private var playButton: some View {
            Button {
                switch manager.playbackRequestStatus {
                case .playing:
                    manager.proxy?.pause()
                    manager.set(playbackRequestStatus: .paused)
                case .paused:
                    manager.proxy?.play()
                    manager.set(playbackRequestStatus: .playing)
                }
            } label: {
                Group {
                    switch manager.playbackRequestStatus {
                    case .playing:
                        Label("Pause", systemImage: "pause.fill")
                    case .paused:
                        Label(L10n.play, systemImage: "play.fill")
//                    case .buffering:
//                        ProgressView()
//                            .scaleEffect(2)
                    }
                }
                .transition(.opacity.combined(with: .scale).animation(.bouncy(duration: 0.7, extraBounce: 0.2)))
                .font(.system(size: 56, weight: .bold, design: .default))
                .contentShape(Rectangle())
                .labelStyle(.iconOnly)
                .padding(20)
            }
            .fixedSize()
        }

        @ViewBuilder
        private var jumpForwardButton: some View {
            Button {
                manager.proxy?.jumpForward(jumpForwardInterval.interval)
            } label: {
                Label(
                    "\(jumpForwardInterval.interval, format: .interval(style: .narrow, fields: [.second]))",
                    systemImage: jumpForwardInterval.forwardSystemImage
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
                manager.proxy?.jumpBackward(jumpBackwardInterval.interval)
            } label: {
                Label(
                    "\(jumpBackwardInterval.interval, format: .interval(style: .narrow, fields: [.second]))",
                    systemImage: jumpBackwardInterval.backwardSystemImage
                )
                .labelStyle(.iconOnly)
                .font(.system(size: 36, weight: .regular, design: .default))
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
                    .frame(minWidth: 100, maxWidth: 300)

                if shouldShowJumpButtons {
                    jumpForwardButton
                }
            }
            .buttonStyle(OverlayButtonStyle(onPressed: onPressed))
        }
    }
}

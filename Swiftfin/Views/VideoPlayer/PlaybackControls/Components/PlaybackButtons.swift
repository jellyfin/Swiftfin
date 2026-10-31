//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

// TODO: adjust button sizes/padding on compact/regular?

extension VideoPlayer.PlaybackControls {

    struct PlaybackButtons: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @Environment(ViewState.self)
        private var viewState
        @Environment(MediaSession.self)
        private var mediaSession

        private var shouldShowJumpButtons: Bool {
            !mediaSession.item.isLiveStream
        }

        private var playButton: some View {
            Button {
                switch mediaSession.playbackRequestStatus {
                case .playing:
                    mediaSession.setPlaybackRequestStatus(status: .paused)
                case .paused:
                    mediaSession.setPlaybackRequestStatus(status: .playing)
                }
            } label: {
                Label(
                    mediaSession.playbackRequestStatus == .playing ? L10n.pause : L10n.play,
                    systemImage: mediaSession.playbackRequestStatus == .playing ? "pause.fill" : "play.fill"
                )
                .font(.system(size: 36, weight: .bold, design: .default))
                .labelStyle(.iconOnly)
                .frame(width: 44, height: 44)
                .padding(16)
            }
            .disabled(!mediaSession.canControlPlayback)
        }

        private var jumpForwardButton: some View {
            JumpButton(interval: jumpForwardInterval, isForward: true) {
                mediaSession.seek(by: jumpForwardInterval.rawValue)
            }
            .disabled(!mediaSession.canSeek)
        }

        private var jumpBackwardButton: some View {
            JumpButton(interval: jumpBackwardInterval, isForward: false) {
                mediaSession.seek(by: .zero - (jumpBackwardInterval.rawValue))
            }
            .disabled(!mediaSession.canSeek)
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
            .buttonStyle(OverlayButtonStyle(symbolEffectSpeed: 2))
            .padding(.horizontal, 50)
        }
    }

    private struct JumpButton: View {

        @State
        private var rotationTrigger = false
        @State
        private var lastRotationStart: ContinuousClock.Instant?

        let interval: MediaJumpInterval
        let isForward: Bool
        let action: () -> Void

        var body: some View {
            Button {
                action()

                let now = ContinuousClock.now

                // A burst gets one finite effect. Further taps still seek immediately,
                // but cannot queue rotations that outlive the user's interaction.
                guard lastRotationStart.map({ $0.duration(to: now) >= .milliseconds(500) }) ?? true
                else { return }

                lastRotationStart = now
                rotationTrigger.toggle()
            } label: {
                Image(systemName: isForward ? interval.systemImage : interval.secondarySystemImage)
                    .symbolEffect(
                        isForward ? .rotate.clockwise.byLayer : .rotate.counterClockwise.byLayer,
                        options: .nonRepeating.speed(10),
                        value: rotationTrigger
                    )
                    .font(.system(size: 28, weight: .regular))
                    .frame(width: 32, height: 32)
                    .padding(8)
            }
            .foregroundStyle(.primary)
            .accessibilityLabel(isForward ? L10n.jumpForward : L10n.jumpBackward)
            .accessibilityValue(interval.rawValue.formatted(Duration.UnitsFormatStyle(allowedUnits: [.seconds], width: .wide)))
        }
    }
}

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
// TODO: jump rotation symbol effects

extension VideoPlayer.PlaybackControls {

    struct PlaybackButtons: View {

        @Default(.VideoPlayer.jumpBackwardInterval)
        private var jumpBackwardInterval
        @Default(.VideoPlayer.jumpForwardInterval)
        private var jumpForwardInterval

        @EnvironmentObject
        private var centerOffsetBox: PublishedBox<CGFloat>
        @Environment(ViewState.self)
        private var viewState
        @EnvironmentObject
        private var manager: MediaPlayerManager

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
                Label(
                    manager.playbackRequestStatus == .playing ? L10n.pause : L10n.play,
                    systemImage: manager.playbackRequestStatus == .playing ? "pause.fill" : "play.fill"
                )
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
                // swiftlint:disable:next hard_coded_display_string
                Label(
                    "\(jumpForwardInterval.rawValue, format: Duration.UnitsFormatStyle(allowedUnits: [.seconds], width: .narrow))",
                    systemImage: jumpForwardInterval.systemImage
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
                // swiftlint:disable:next hard_coded_display_string
                Label(
                    "\(jumpBackwardInterval.rawValue, format: Duration.UnitsFormatStyle(allowedUnits: [.seconds], width: .narrow))",
                    systemImage: jumpBackwardInterval.secondarySystemImage
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
            .buttonStyle(OverlayButtonStyle())
            .padding(.horizontal, 50)
            .offset(y: centerOffsetBox.value / 2)
        }
    }
}

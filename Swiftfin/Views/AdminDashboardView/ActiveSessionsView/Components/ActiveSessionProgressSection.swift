//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ActiveSessionsView {

    struct ProgressSection: View {

        @Default(.accentColor)
        private var accentColor

        let item: BaseItemDto
        let playState: PlayerStateInfo
        let transcodingInfo: TranscodingInfo?

        private var playbackPercentage: Double {
            clamp(Double(playState.positionTicks ?? 0) / Double(item.runTimeTicks ?? 1), min: 0, max: 1)
        }

        private var transcodingPercentage: Double? {
            guard let c = transcodingInfo?.completionPercentage else { return nil }
            return clamp(c / 100.0, min: 0, max: 1)
        }

        @ViewBuilder
        private var playbackInformation: some View {
            HStack {
                if playState.isPaused ?? false {
                    Image(systemName: "pause.fill")
                        .transition(.opacity.combined(with: .scale).animation(.bouncy))
                } else {
                    Image(systemName: "play.fill")
                        .transition(.opacity.combined(with: .scale).animation(.bouncy))
                }

                if let playMethod = playState.playMethod, playMethod == .transcode {
                    Text(playMethod)
                }

                Spacer()

                HStack(spacing: 2) {
                    Text(playState.positionSeconds ?? 0, format: .runtime)

                    Text("/")

                    Text(item.runTimeSeconds, format: .runtime)
                }
                .monospacedDigit()
            }
            .font(.subheadline)
        }

        var body: some View {
            VStack {
                ProgressView(value: playbackPercentage)
                    .progressViewStyle(.playback(secondaryProgress: transcodingPercentage))
                    .frame(height: 5)
                    .foregroundStyle(.primary, .secondary, .orange)

                playbackInformation
            }
        }
    }
}

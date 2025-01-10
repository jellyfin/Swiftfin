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

    struct SplitTimeStamp: View {

        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.scrubbedSeconds)
        @Binding
        private var scrubbedSeconds: TimeInterval

        @EnvironmentObject
        private var manager: MediaPlayerManager

        @ViewBuilder
        private var leadingTimestamp: some View {
            HStack(spacing: 2) {

                Text(scrubbedSeconds, format: .runtime)

                Group {
                    Text("/")

                    Text(manager.seconds, format: .runtime)
                }
                .foregroundStyle(.secondary)
                .isVisible(isScrubbing)
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {
                Group {
                    Text(manager.item.runTimeSeconds - manager.seconds, format: .runtime.negated)

                    Text("/")
                }
                .foregroundStyle(.secondary)
                .isVisible(isScrubbing)

                switch trailingTimestampType {
                case .timeLeft:
                    Text(manager.item.runTimeSeconds - scrubbedSeconds, format: .runtime.negated)
                case .totalTime:
                    Text(manager.item.runTimeSeconds, format: .runtime)
                }
            }
        }

        var body: some View {
            Button {
                switch trailingTimestampType {
                case .timeLeft:
                    trailingTimestampType = .totalTime
                case .totalTime:
                    trailingTimestampType = .timeLeft
                }
            } label: {
                HStack {
                    leadingTimestamp

                    Spacer()

                    trailingTimestamp
                }
                .monospacedDigit()
                .font(.caption)
                .lineLimit(1)
            }
            .foregroundStyle(.primary, .secondary)
        }
    }
}

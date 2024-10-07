//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
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

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedProgress: ProgressBox

        @ViewBuilder
        private var leadingTimestamp: some View {
            HStack(spacing: 2) {

                Text(scrubbedProgress.seconds, format: .runtime)
                    .foregroundStyle(.primary)

                if isScrubbing {
                    Group {
                        Text("/")

                        Text(manager.progress.seconds, format: .runtime)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {
                if isScrubbing {
                    Group {
                        Text(manager.item.runTimeSeconds - manager.progress.seconds, format: .runtime.negated)

                        Text("/")
                    }
                    .foregroundStyle(.secondary)
                }

                Group {
                    switch trailingTimestampType {
                    case .timeLeft:
                        Text(manager.item.runTimeSeconds - scrubbedProgress.seconds, format: .runtime.negated)
                    case .totalTime:
                        Text(manager.item.runTimeSeconds, format: .runtime)
                    }
                }
                .foregroundStyle(.primary)
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

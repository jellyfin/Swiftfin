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

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        @State
        private var activeSeconds: Duration = .zero

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        @ViewBuilder
        private var leadingTimestamp: some View {
            HStack(spacing: 2) {

                Text(scrubbedSeconds, format: .runtime)

                Group {
                    Text("/")

                    Text(activeSeconds, format: .runtime)
                }
                .foregroundStyle(.secondary)
                .isVisible(isScrubbing)
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {
                Group {
                    if let runtime = manager.item.runtime {
                        Text(runtime - activeSeconds, format: .runtime)
                    } else {
                        Text(verbatim: .emptyRuntime)
                    }

                    Text("/")
                }
                .foregroundStyle(.secondary)
                .isVisible(isScrubbing)

                if let runtime = manager.item.runtime {
                    switch trailingTimestampType {
                    case .timeLeft:
                        Text(.zero - (runtime - scrubbedSeconds), format: .runtime)
                    case .totalTime:
                        Text(runtime, format: .runtime)
                    }
                } else {
                    Text(verbatim: .emptyRuntime)
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
            .onReceive(manager.secondsBox.$value) { newValue in
                activeSeconds = newValue
            }
        }
    }
}

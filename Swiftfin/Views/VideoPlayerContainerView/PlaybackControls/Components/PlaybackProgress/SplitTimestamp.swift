//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct SplitTimeStamp: View {

        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>
        @EnvironmentObject
        private var manager: MediaPlayerManager

        @State
        private var activeSeconds: Duration = .zero

        private var isScrubbing: Bool {
            containerState.isScrubbing
        }

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
            HStack {
                Button {
                    switch trailingTimestampType {
                    case .timeLeft:
                        trailingTimestampType = .totalTime
                    case .totalTime:
                        trailingTimestampType = .timeLeft
                    }
                } label: {
                    leadingTimestamp
                }
                .foregroundStyle(.primary, .secondary)

                Spacer()

                Button {
                    switch trailingTimestampType {
                    case .timeLeft:
                        trailingTimestampType = .totalTime
                    case .totalTime:
                        trailingTimestampType = .timeLeft
                    }
                } label: {
                    trailingTimestamp
                }
                .foregroundStyle(.primary, .secondary)
            }
            .monospacedDigit()
            .font(.caption2)
            .lineLimit(1)
            .foregroundStyle(isScrubbing ? .primary : .secondary, .secondary)
            .assign(manager.secondsBox.$value, to: $activeSeconds)
        }
    }
}

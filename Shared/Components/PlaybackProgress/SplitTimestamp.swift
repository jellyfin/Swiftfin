//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension VideoPlayer.PlaybackControls {

    struct SplitTimeStamp: View {

        @EnvironmentObject
        private var manager: MediaPlayerManager
        @EnvironmentObject
        private var scrubbedSecondsBox: PublishedBox<Duration>

        #if os(iOS)
        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType

        @EnvironmentObject
        private var containerState: VideoPlayerContainerState

        @State
        private var activeSeconds: Duration = .zero
        #elseif os(tvOS)
        @State
        private var contentSize: CGSize = .zero
        @State
        private var leadingTimestampSize: CGSize = .zero
        @State
        private var trailingTimestampSize: CGSize = .zero
        #endif

        private var scrubbedSeconds: Duration {
            scrubbedSecondsBox.value
        }

        #if os(iOS)
        private var isScrubbing: Bool {
            containerState.isScrubbing
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

        #elseif os(tvOS)
        private var scrubbedProgress: Double {
            guard let runtime = manager.item.runtime, runtime > .zero else { return 0 }
            return scrubbedSeconds / runtime
        }

        private var previewXOffset: CGFloat {
            let p = contentSize.width * scrubbedProgress - (leadingTimestampSize.width / 2)
            return clamp(p, min: 0, max: contentSize.width - (trailingTimestampSize.width + leadingTimestampSize.width))
        }
        #endif

        var body: some View {
            #if os(iOS)
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
            #else
            ZStack {
                if let runtime = manager.item.runtime {
                    Text(.zero - (runtime - scrubbedSeconds), format: .runtime)
                } else {
                    Text(verbatim: .emptyRuntime)
                }
            }
            .trackingSize($trailingTimestampSize)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .debugBackground()
            .overlay(alignment: .leading) {
                Text(scrubbedSeconds, format: .runtime)
                    .trackingSize($leadingTimestampSize)
                    .offset(x: previewXOffset)
            }
            .font(.callout)
            .monospacedDigit()
            .trackingSize($contentSize)
            #endif
        }
    }
}

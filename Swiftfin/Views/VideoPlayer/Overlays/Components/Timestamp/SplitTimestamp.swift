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

        @Default(.VideoPlayer.Overlay.showCurrentTimeWhileScrubbing)
        private var showCurrentTimeWhileScrubbing
        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType

//        @EnvironmentObject
//        private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @EnvironmentObject
        private var manager: VideoPlayerManager
        @EnvironmentObject
        private var progress: ProgressBox

        @ViewBuilder
        private var leadingTimestamp: some View {
            HStack(spacing: 2) {

                Text(progress.seconds.timeLabel)
                    .foregroundColor(.white)

                if isScrubbing && showCurrentTimeWhileScrubbing {
                    Group {
                        Text("/")
                        
                        Text(progress.seconds.timeLabel)
                    }
                    .foregroundStyle(.secondary)
                }
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {
                if isScrubbing && showCurrentTimeWhileScrubbing {
                    Group {
                        Text((manager.item.runTimeSeconds - progress.seconds).timeLabel.prepending("-"))
                        
                        Text("/")
                    }
                    .foregroundStyle(.secondary)
                }

                switch trailingTimestampType {
                case .timeLeft:
                    Text((manager.item.runTimeSeconds - progress.seconds).timeLabel.prepending("-"))
                        .foregroundStyle(.white)
                case .totalTime:
                    Text(manager.item.runTimeSeconds.timeLabel)
                        .foregroundStyle(.white)
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
        }
    }
}

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

        @Default(.VideoPlayer.Overlay.showCurrentTimeWhileScrubbing)
        private var showCurrentTimeWhileScrubbing
        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType

        @EnvironmentObject
        private var currentProgressHandler: VideoPlayerManager.CurrentProgressHandler
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @ViewBuilder
        private var leadingTimestamp: some View {
            HStack(spacing: 2) {

                Text(currentProgressHandler.scrubbedSeconds.timeLabel)
                    .foregroundColor(.white)

                if isScrubbing && showCurrentTimeWhileScrubbing {
                    Text("/")
                        .foregroundColor(Color(UIColor.lightText))

                    Text(currentProgressHandler.seconds.timeLabel)
                        .foregroundColor(Color(UIColor.lightText))
                }
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {
                if isScrubbing && showCurrentTimeWhileScrubbing {
                    Text((viewModel.item.runTimeSeconds - currentProgressHandler.seconds).timeLabel.prepending("-"))
                        .foregroundColor(Color(UIColor.lightText))

                    Text("/")
                        .foregroundColor(Color(UIColor.lightText))
                }

                switch trailingTimestampType {
                case .timeLeft:
                    Text((viewModel.item.runTimeSeconds - currentProgressHandler.scrubbedSeconds).timeLabel.prepending("-"))
                        .foregroundColor(.white)
                case .totalTime:
                    Text(viewModel.item.runTimeSeconds.timeLabel)
                        .foregroundColor(.white)
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

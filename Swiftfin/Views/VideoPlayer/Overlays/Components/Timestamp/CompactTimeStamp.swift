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

    struct CompactTimeStamp: View {

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
            Button {
                switch trailingTimestampType {
                case .timeLeft:
                    trailingTimestampType = .totalTime
                case .totalTime:
                    trailingTimestampType = .timeLeft
                }
            } label: {
                HStack(spacing: 2) {

                    Text(currentProgressHandler.scrubbedSeconds.timeLabel)
                        .foregroundColor(.white)

                    Text("/")
                        .foregroundColor(Color(UIColor.lightText))

                    switch trailingTimestampType {
                    case .timeLeft:
                        Text((viewModel.item.runTimeSeconds - currentProgressHandler.scrubbedSeconds).timeLabel.prepending("-"))
                            .foregroundColor(Color(UIColor.lightText))
                    case .totalTime:
                        Text(viewModel.item.runTimeSeconds.timeLabel)
                            .foregroundColor(Color(UIColor.lightText))
                    }
                }
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {

                Text(currentProgressHandler.seconds.timeLabel)

                Text("/")

                Text((viewModel.item.runTimeSeconds - currentProgressHandler.seconds).timeLabel)
            }
            .foregroundColor(Color(UIColor.lightText))
        }

        var body: some View {
            HStack {
                leadingTimestamp

                Spacer()

                if isScrubbing && showCurrentTimeWhileScrubbing {
                    trailingTimestamp
                }
            }
            .monospacedDigit()
            .font(.caption)
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ItemVideoPlayer.Overlay {

    struct CompactTimeStamp: View {

        @Default(.VideoPlayer.Overlay.showCurrentTimeWhileScrubbing)
        private var showCurrentTimeWhileScrubbing
        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.scrubbedProgress)
        @Binding
        private var scrubbedProgress: CGFloat

        @EnvironmentObject
        private var currentSecondsHandler: VideoPlayerManager.CurrentPlaybackInformation
        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel

        @Binding
        var currentSeconds: Int

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

                    Text(Double(currentSeconds).timeLabel)
                        .foregroundColor(.white)

                    Text("/")
                        .foregroundColor(Color(UIColor.lightText))

                    switch trailingTimestampType {
                    case .timeLeft:
                        Text(Double(viewModel.item.runTimeSeconds - currentSeconds).timeLabel.prepending("-"))
                            .foregroundColor(Color(UIColor.lightText))
                    case .totalTime:
                        Text(Double(viewModel.item.runTimeSeconds).timeLabel)
                            .foregroundColor(Color(UIColor.lightText))
                    }
                }
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {

                Text(Double(currentSecondsHandler.currentSeconds).timeLabel)

                Text("/")

                Text(Double(viewModel.item.runTimeSeconds - currentSecondsHandler.currentSeconds).timeLabel)
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

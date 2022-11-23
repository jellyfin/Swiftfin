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

    struct SplitTimeStamp: View {

        @Default(.VideoPlayer.Overlay.showCurrentTimeWhileScrubbing)
        private var showCurrentTimeWhileScrubbing
        @Default(.VideoPlayer.Overlay.trailingTimestampType)
        private var trailingTimestampType

        @EnvironmentObject
        private var viewModel: VideoPlayerViewModel
        
        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool
        @Environment(\.progress)
        @Binding
        private var progress: CGFloat
        @Environment(\.seconds)
        @Binding
        private var seconds: Int
        @Environment(\.scrubbedProgress)
        @Binding
        private var scrubbedProgress: CGFloat
        @Environment(\.scrubbedSeconds)
        @Binding
        private var scrubbedSeconds: Int

        @ViewBuilder
        private var leadingTimestamp: some View {
            HStack(spacing: 2) {

                Text(Double(scrubbedSeconds).timeLabel)
                    .foregroundColor(.white)

                if isScrubbing && showCurrentTimeWhileScrubbing {
                    Text("/")
                        .foregroundColor(Color(UIColor.lightText))

                    Text(Double(seconds).timeLabel)
                        .foregroundColor(Color(UIColor.lightText))
                }
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {
                if isScrubbing && showCurrentTimeWhileScrubbing {
                    Text(Double(viewModel.item.runTimeSeconds - seconds).timeLabel.prepending("-"))
                        .foregroundColor(Color(UIColor.lightText))

                    Text("/")
                        .foregroundColor(Color(UIColor.lightText))
                }

                switch trailingTimestampType {
                case .timeLeft:
                    Text(Double(viewModel.item.runTimeSeconds - scrubbedSeconds).timeLabel.prepending("-"))
                        .foregroundColor(.white)
                case .totalTime:
                    Text(Double(viewModel.item.runTimeSeconds).timeLabel)
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

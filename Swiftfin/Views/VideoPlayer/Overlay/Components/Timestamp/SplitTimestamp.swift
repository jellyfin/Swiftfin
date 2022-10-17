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
        @Default(.VideoPlayer.Overlay.timeLeftTimestamp)
        private var timeLeftTimestamp

        @Environment(\.isScrubbing)
        @Binding
        private var isScrubbing: Bool

        @EnvironmentObject
        private var currentSecondsHandler: CurrentSecondsHandler
        @EnvironmentObject
        private var viewModel: ItemVideoPlayerViewModel

        @Binding
        var currentSeconds: Int

        @ViewBuilder
        private var leadingTimestamp: some View {
            HStack(spacing: 2) {

                Text(Double(currentSeconds).timeLabel)
                    .foregroundColor(.white)

                if isScrubbing && showCurrentTimeWhileScrubbing {
                    Text("/")
                        .foregroundColor(Color(UIColor.lightText))

                    Text(Double(currentSecondsHandler.currentSeconds).timeLabel)
                        .foregroundColor(Color(UIColor.lightText))
                }
            }
        }

        @ViewBuilder
        private var trailingTimestamp: some View {
            HStack(spacing: 2) {
                if isScrubbing && showCurrentTimeWhileScrubbing {
                    Text(Double(viewModel.item.runTimeSeconds - currentSecondsHandler.currentSeconds).timeLabel.prepending("-"))
                        .foregroundColor(Color(UIColor.lightText))

                    Text("/")
                        .foregroundColor(Color(UIColor.lightText))
                }

                if timeLeftTimestamp {
                    Text(Double(viewModel.item.runTimeSeconds - currentSeconds).timeLabel.prepending("-"))
                        .foregroundColor(.white)
                } else {
                    Text(Double(viewModel.item.runTimeSeconds).timeLabel)
                        .foregroundColor(.white)
                }
            }
        }

        var body: some View {
            Button {
                timeLeftTimestamp.toggle()
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

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ActiveSessionRowView {
    struct ProgressSection: View {
        let item: BaseItemDto?
        let playState: PlayerStateInfo?
        let transcodingInfo: TranscodingInfo?

        init(session: SessionInfo) {
            self.item = session.nowPlayingItem
            self.playState = session.playState
            self.transcodingInfo = session.transcodingInfo
        }

        var body: some View {
            VStack {
                playbackInformation
                    .foregroundColor(.secondary)
                playbackTimeline
                    .foregroundColor(.primary)
            }
        }

        @ViewBuilder
        private var playbackInformation: some View {
            HStack {
                if let playMethod = playState?.playMethod {
                    Text(playMethod.rawValue)
                }
                Spacer()
                if let transcodingInfo = transcodingInfo {
                    Text(getTranscodeFPS(transcodingInfo: transcodingInfo))
                }
                Spacer()
                if let playState = playState {
                    Text(
                        getProgressTimestamp(
                            item: item,
                            playState: playState
                        )
                    )
                }
            }
        }

        @ViewBuilder
        private var playbackTimeline: some View {
            HStack {
                getProgressIcon(isPaused: playState?.isPaused)

                TimelineSection(
                    playbackPercentage: Double(playState?.positionTicks ?? 0) / Double(item?.runTimeTicks ?? 0),
                    transcodingPercentage: (transcodingInfo?.completionPercentage ?? 0) / 100.0
                )
            }
        }

        private func formattedTime(_ ticks: Int64) -> String {
            let seconds = ticks / 10_000_000
            return seconds.timeLabel
        }

        private func getProgressPercentage(item: BaseItemDto?, playState: PlayerStateInfo?) -> Double? {
            let positionTicks = playState?.positionTicks ?? 0
            let totalTicks = item?.runTimeTicks ?? 0

            if totalTicks == 0 {
                return nil
            } else {
                return Double(positionTicks) / Double(totalTicks)
            }
        }

        private func getProgressIcon(isPaused: Bool?) -> Image? {
            if isPaused ?? false {
                Image(systemName: "pause.fill")
            } else {
                Image(systemName: "play.fill")
            }
        }

        private func getProgressTimestamp(item: BaseItemDto?, playState: PlayerStateInfo?) -> String {
            let positionTicks = playState?.positionTicks ?? 0
            let totalTicks = item?.runTimeTicks ?? 0

            return L10n.itemOverItem(
                formattedTime(Int64(positionTicks)),
                formattedTime(Int64(totalTicks))
            )
        }

        private func getTranscodeFPS(transcodingInfo: TranscodingInfo) -> String {
            if let framerate = transcodingInfo.framerate {
                return Int(framerate).description + "fps"
            } else {
                return ""
            }
        }
    }
}

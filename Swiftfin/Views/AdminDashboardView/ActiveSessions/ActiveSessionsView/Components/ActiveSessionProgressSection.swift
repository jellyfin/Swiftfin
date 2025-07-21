//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ActiveSessionsView {

    struct ProgressSection: View {

        @Default(.accentColor)
        private var accentColor

        private let item: BaseItemDto
        private let playState: PlayerStateInfo
        private let transcodingInfo: TranscodingInfo?
        private let showTranscodeReason: Bool

        private var playbackPercentage: Double {
            clamp(Double(playState.positionTicks ?? 0) / Double(item.runTimeTicks ?? 1), min: 0, max: 1)
        }

        private var transcodingPercentage: Double? {
            guard let c = transcodingInfo?.completionPercentage else { return nil }
            return clamp(c / 100.0, min: 0, max: 1)
        }

        init(item: BaseItemDto, playState: PlayerStateInfo, transcodingInfo: TranscodingInfo?, showTranscodeReason: Bool = false) {
            self.item = item
            self.playState = playState
            self.transcodingInfo = transcodingInfo
            self.showTranscodeReason = showTranscodeReason
        }

        @ViewBuilder
        private var playbackInformation: some View {
            HStack(alignment: .top) {
                FlowLayout(
                    alignment: .leading,
                    direction: .down,
                    spacing: 4,
                    lineSpacing: 4,
                    minRowLength: 1
                ) {
                    if playState.isPaused ?? false {
                        Image(systemName: "pause.fill")
                            .transition(.opacity.combined(with: .scale).animation(.bouncy))
                            .padding(.trailing, 8)
                    } else {
                        Image(systemName: "play.fill")
                            .transition(.opacity.combined(with: .scale).animation(.bouncy))
                            .padding(.trailing, 8)
                    }

                    if let playMethod = playState.playMethod,
                       let transcodeReasons = transcodingInfo?.transcodeReasons,
                       playMethod == .transcode
                    {
                        if showTranscodeReason {
                            let transcodeIcons = Set(transcodeReasons.map(\.systemImage)).sorted()

                            ForEach(transcodeIcons, id: \.self) { icon in
                                Image(systemName: icon)
                                    .foregroundStyle(.secondary)
                                    .symbolRenderingMode(.monochrome)
                            }
                        }

                        Text(playMethod)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                HStack(spacing: 2) {
                    Text(playState.position ?? .zero, format: .runtime)

                    Text("/")

                    Text(item.runtime ?? .zero, format: .runtime)
                }
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: true)
            }
            .font(.subheadline)
        }

        var body: some View {
            VStack {
                ProgressView(value: playbackPercentage)
                    .progressViewStyle(.playback.secondaryProgress(transcodingPercentage))
                    .frame(height: 5)
                    .foregroundStyle(.primary, .secondary, .orange)

                playbackInformation
            }
        }
    }
}

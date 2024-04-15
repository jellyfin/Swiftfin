//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension ChannelsView {

    struct ChannelGridItem: View {

        let channel: ChannelProgram

        @ViewBuilder
        private func currentProgramView(_ currentProgram: BaseItemDto) -> some View {
            VStack(alignment: .leading, spacing: 5) {
                Text(currentProgram.displayTitle)
                    .font(.footnote)
                    .fontWeight(.bold)
                    .lineLimit(1)

                ProgressBar(progress: currentProgram.programProgress ?? 0)
                    .frame(height: 5)

                if let startDate = currentProgram.startDate, let endDate = currentProgram.endDate {
                    HStack {
                        Text(startDate, style: .time)

                        Spacer()

                        Text(endDate, style: .time)
                    }
                    .font(.footnote.weight(.bold))
                    .foregroundStyle(.secondary)
                }
            }
        }

        var body: some View {
            Button {} label: {
                HStack(alignment: .center, spacing: EdgeInsets.defaultEdgePadding) {
                    VStack {
                        ZStack {
                            Color.clear

                            ImageView(channel.portraitPosterImageSource(maxWidth: 80))
                                .failure {
                                    SystemImageContentView(systemName: channel.typeSystemImage)
                                        .background(color: .clear)
                                        .imageFrameRatio(width: 1, height: 1)
                                }
                        }
                        .aspectRatio(1.0, contentMode: .fill)

                        Text(channel.channel.number ?? "")
                            .font(.body)
                            .lineLimit(1)
                            .foregroundColor(Color.jellyfinPurple)
                    }
                    .frame(width: 80)
                    .padding(.vertical, 8)

                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(channel.displayTitle)
                                .font(.body)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .foregroundColor(Color.jellyfinPurple)

                            if let currentProgram = channel.currentProgram {
                                currentProgramView(currentProgram)
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
            }
            .buttonStyle(.plain)
            .background {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.secondarySystemFill)
            }
        }
    }
}

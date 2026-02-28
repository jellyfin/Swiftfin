//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension ChannelLibraryView {

    struct WideChannelGridItem: View {

        @Default(.accentColor)
        private var accentColor

        @State
        private var now: Date = .now

        let channel: ChannelProgram

        private var onSelect: () -> Void
        private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

        @ViewBuilder
        private var channelLogo: some View {
            VStack {
                ZStack {
                    Color.clear

                    ImageView(channel.portraitImageSources(maxWidth: 110, quality: 90))
                        .image {
                            $0.aspectRatio(contentMode: .fit)
                        }
                        .failure {
                            SystemImageContentView(systemName: channel.systemImage, ratio: 0.66)
                        }
                        .placeholder { _ in
                            EmptyView()
                        }
                }
                .aspectRatio(1.0, contentMode: .fit)

                Text(channel.channel.number ?? "")
                    .font(.body)
                    .lineLimit(1)
                    .foregroundStyle(.primary)
            }
        }

        @ViewBuilder
        private func programLabel(for program: BaseItemDto) -> some View {
            HStack(alignment: .top, spacing: EdgeInsets.edgePadding / 2) {
                AlternateLayoutView(alignment: .leading) {
                    Text("00:00 AM")
                        .monospacedDigit()
                } content: {
                    if let startDate = program.startDate {
                        Text(startDate, style: .time)
                            .monospacedDigit()
                    } else {
                        Text(String.emptyDash)
                    }
                }

                Text(program.displayTitle)
            }
            .lineLimit(1)
        }

        @ViewBuilder
        private var programListView: some View {
            VStack(alignment: .leading, spacing: 0) {
                if let currentProgram = channel.currentProgram {
                    ProgressBar(progress: currentProgram.programProgress(relativeTo: now) ?? 0)
                        .frame(height: 8)
                        .padding(.bottom, 8)
                        .foregroundStyle(accentColor)

                    programLabel(for: currentProgram)
                        .font(.caption.weight(.bold))
                }

                if let nextProgram = channel.programAfterCurrent(offset: 0) {
                    programLabel(for: nextProgram)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let futureProgram = channel.programAfterCurrent(offset: 1) {
                    programLabel(for: futureProgram)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .id(channel.currentProgram)
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                HStack(alignment: .center, spacing: EdgeInsets.edgePadding / 2) {

                    channelLogo
                        .frame(width: 110)

                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text(channel.displayTitle)
                                .font(.body)
                                .fontWeight(.bold)
                                .lineLimit(1)
                                .foregroundStyle(.primary)

                            if channel.programs.isNotEmpty {
                                programListView
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal, EdgeInsets.edgePadding / 2)
            }
            .buttonStyle(.card)
            .frame(height: 200)
            .onReceive(timer) { newValue in
                now = newValue
            }
            .animation(.linear(duration: 0.2), value: channel.currentProgram)
        }
    }
}

extension ChannelLibraryView.WideChannelGridItem {

    init(channel: ChannelProgram) {
        self.init(
            channel: channel,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

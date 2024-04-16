//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

extension LiveTVChannelLibraryView {

    struct WideChannelGridItem: View {

        @State
        private var now: Date = .now

        let channel: ChannelProgram

        private var onSelect: () -> Void
        private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

        @ViewBuilder
        private func programLabel(for program: BaseItemDto) -> some View {
            HStack(alignment: .top) {
                if let startDate = program.startDate {
                    Text(startDate, style: .time)
                        .monospacedDigit()
                } else {
                    Text(String.emptyDash)
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
                        .frame(height: 5)
                        .padding(.bottom, 5)

                    programLabel(for: currentProgram)
                        .font(.footnote.weight(.bold))
                }

                if let nextProgram = channel.programAfterCurrent(offset: 0) {
                    programLabel(for: nextProgram)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }

                if let futureProgram = channel.programAfterCurrent(offset: 1) {
                    programLabel(for: futureProgram)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }
            .id(channel.currentProgram)
        }

        var body: some View {
            Button {
                onSelect()
            } label: {
                HStack(alignment: .center, spacing: EdgeInsets.defaultEdgePadding) {
                    VStack {
                        ZStack {
                            Color.clear

                            ImageView(channel.portraitPosterImageSource(maxWidth: 80))
                                .image {
                                    $0.aspectRatio(contentMode: .fit)
                                }
                                .failure {
                                    SystemImageContentView(systemName: channel.typeSystemImage)
                                        .background(color: .clear)
                                        .imageFrameRatio(width: 1.5, height: 1.5)
                                }
                                .placeholder {
                                    EmptyView()
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

                            if channel.programs.isNotEmpty {
                                programListView
                            }
                        }

                        Spacer()
                    }
                    .frame(maxWidth: .infinity)
                }
                .padding(.horizontal, 8)
                .background {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.secondarySystemFill)
                }
            }
            .buttonStyle(.plain)
            .onReceive(timer) { newValue in
                now = newValue
            }
            .animation(.linear(duration: 0.2), value: channel.currentProgram)
        }
    }
}

extension LiveTVChannelLibraryView.WideChannelGridItem {

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

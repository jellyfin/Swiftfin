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

// TODO: can look busy with 3 programs, probably just do 2?

extension ChannelLibraryView {

    struct DetailedChannelView: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.colorScheme)
        private var colorScheme

        @State
        private var contentSize: CGSize = .zero
        @State
        private var now: Date = .now

        let channel: ChannelProgram

        private var onSelect: () -> Void
        private let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()

        @ViewBuilder
        private var channelLogo: some View {
            VStack {
                ZStack {
                    Color.secondarySystemFill
                        .opacity(colorScheme == .dark ? 0.5 : 1)
                        .posterShadow()

                    ImageView(channel.channel.imageSource(.primary, maxWidth: 120))
                        .image {
                            $0.aspectRatio(contentMode: .fit)
                        }
                        .failure {
                            SystemImageContentView(systemName: channel.systemImage, ratio: 0.5)
                                .background(color: .clear)
                        }
                        .placeholder { _ in
                            EmptyView()
                        }
                        .padding(5)
                }
                .aspectRatio(1.0, contentMode: .fill)
                .posterBorder(ratio: 0.0375, of: \.width)
                .cornerRadius(ratio: 0.0375, of: \.width)

                Text(channel.channel.number ?? "")
                    .font(.body)
                    .lineLimit(1)
                    .foregroundColor(Color.jellyfinPurple)
            }
        }

        @ViewBuilder
        private func programLabel(for program: BaseItemDto) -> some View {
            HStack(alignment: .top) {
                AlternateLayoutView(alignment: .leading) {
                    Text("00:00 AAA")
                        .monospacedDigit()
                } content: {
                    if let startDate = program.startDate {
                        Text(startDate, style: .time)
                            .monospacedDigit()
                    } else {
                        Text(String.emptyTime)
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
                        .frame(height: 5)
                        .padding(.bottom, 5)
                        .foregroundStyle(accentColor)

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
            ZStack(alignment: .bottomTrailing) {
                Button {
                    onSelect()
                } label: {
                    HStack(alignment: .center, spacing: EdgeInsets.edgePadding) {

                        channelLogo
                            .frame(width: 80)
                            .padding(.vertical, 8)

                        HStack {
                            VStack(alignment: .leading, spacing: 5) {
                                Text(channel.displayTitle)
                                    .font(.body)
                                    .fontWeight(.semibold)
                                    .lineLimit(1)
                                    .foregroundStyle(.primary)

                                if channel.programs.isNotEmpty {
                                    programListView
                                }
                            }

                            Spacer()
                        }
                        .frame(maxWidth: .infinity)
                        .trackingSize($contentSize)
                    }
                }
                .buttonStyle(.plain)

                Color.secondarySystemFill
                    .frame(width: contentSize.width, height: 1)
            }
            .onReceive(timer) { newValue in
                now = newValue
            }
            .animation(.linear(duration: 0.2), value: channel.currentProgram)
        }
    }
}

extension ChannelLibraryView.DetailedChannelView {

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

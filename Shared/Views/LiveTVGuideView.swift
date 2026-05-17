//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct LiveTVGuideView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = LiveTVGuideViewModel()

    private let halfHourWidth: CGFloat = UIDevice.isTV ? 260 : 160
    private let rowHeight: CGFloat = UIDevice.isTV ? 116 : 86
    private let channelWidth: CGFloat = UIDevice.isTV ? 260 : 132

    private var hourMarks: [Date] {
        var marks: [Date] = []
        var date = viewModel.minDate.roundedDownToHour

        while date <= viewModel.maxDate {
            marks.append(date)
            date = Calendar.current.date(byAdding: .hour, value: 1, to: date) ?? date.addingTimeInterval(3600)
        }

        return marks
    }

    private var guideWidth: CGFloat {
        max(halfHourWidth * 2, width(for: viewModel.minDate, end: viewModel.maxDate))
    }

    private func width(for start: Date, end: Date) -> CGFloat {
        let seconds = max(900, end.timeIntervalSince(start))
        return CGFloat(seconds / 1800) * halfHourWidth
    }

    private func playableChannel(for channel: ChannelProgram) -> BaseItemDto {
        channel.channel
    }

    @ViewBuilder
    private var contentView: some View {
        ScrollView([.horizontal, .vertical], showsIndicators: true) {
            LazyVStack(alignment: .leading, spacing: 1, pinnedViews: [.sectionHeaders]) {
                Section {
                    ForEach(Array(viewModel.channels.enumerated()), id: \.element.id) { index, channel in
                        guideRow(channel: channel)
                            .onAppear {
                                viewModel.loadNextPageIfNeeded(currentIndex: index)
                            }
                    }

                    if viewModel.isLoadingNextPage {
                        HStack {
                            ProgressView()
                                .padding(.trailing, 8)
                            Text("Loading channels")
                                .foregroundStyle(.secondary)
                        }
                        .frame(width: channelWidth + guideWidth, height: rowHeight)
                    }
                } header: {
                    timelineHeader
                }
            }
            .padding(.bottom, EdgeInsets.edgePadding)
        }
    }

    private var timelineHeader: some View {
        HStack(spacing: 0) {
            Text("Guide")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)
                .frame(width: channelWidth, height: 38, alignment: .leading)
                .padding(.leading, EdgeInsets.edgePadding)
                .background(Color.black.opacity(0.95))

            HStack(spacing: 0) {
                ForEach(hourMarks, id: \.self) { date in
                    Text(date, style: .time)
                        .font(.caption.weight(.semibold))
                        .monospacedDigit()
                        .foregroundStyle(.secondary)
                        .frame(width: halfHourWidth * 2, height: 38, alignment: .leading)
                }
            }
            .frame(width: guideWidth, alignment: .leading)
            .background(Color.black.opacity(0.95))
        }
    }

    private func guideRow(channel: ChannelProgram) -> some View {
        HStack(spacing: 0) {
            channelButton(channel: channel)
                .frame(width: channelWidth, height: rowHeight)
                .background(Color.secondarySystemFill.opacity(0.45))

            HStack(spacing: 1) {
                let visiblePrograms = channel.programs.filter { program in
                    guard let startDate = program.startDate, let endDate = program.endDate else { return false }
                    return endDate > viewModel.minDate && startDate < viewModel.maxDate
                }

                if visiblePrograms.isEmpty {
                    emptyProgramCard
                        .frame(width: guideWidth, height: rowHeight)
                } else {
                    ForEach(visiblePrograms, id: \.id) { program in
                        programButton(program: program, channel: channel)
                            .frame(
                                width: width(
                                    for: max(program.startDate ?? viewModel.minDate, viewModel.minDate),
                                    end: min(program.endDate ?? viewModel.maxDate, viewModel.maxDate)
                                ),
                                height: rowHeight
                            )
                    }
                }
            }
            .frame(width: guideWidth, alignment: .leading)
        }
    }

    private func channelButton(channel: ChannelProgram) -> some View {
        Button {
            play(channel: channel)
        } label: {
            HStack(spacing: 10) {
                PosterImage(item: channel.channel, type: .square)
                    .frame(width: UIDevice.isTV ? 70 : 46, height: UIDevice.isTV ? 70 : 46)

                VStack(alignment: .leading, spacing: 4) {
                    if let number = channel.channel.number, number.isNotEmpty {
                        Text(number)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                    }

                    Text(channel.channel.displayTitle)
                        .font(.callout.weight(.semibold))
                        .lineLimit(2)
                        .foregroundStyle(.primary)
                }

                Spacer(minLength: 0)
            }
            .padding(.horizontal, EdgeInsets.edgePadding)
        }
        .buttonStyle(.plain)
    }

    private func programButton(program: BaseItemDto, channel: ChannelProgram) -> some View {
        Button {
            play(channel: channel)
        } label: {
            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    if let startDate = program.startDate {
                        Text(startDate, style: .time)
                    }

                    if let endDate = program.endDate {
                        Text("- " + endDate.formatted(date: .omitted, time: .shortened))
                    }
                }
                .font(.caption2)
                .monospacedDigit()
                .foregroundStyle(.secondary)

                Text(program.displayTitle)
                    .font(.callout.weight(.semibold))
                    .lineLimit(2)
                    .foregroundStyle(.primary)

                if let overview = program.overview, overview.isNotEmpty, UIDevice.isTV {
                    Text(overview)
                        .font(.caption)
                        .lineLimit(1)
                        .foregroundStyle(.secondary)
                }

                Spacer(minLength: 0)

                if program.isAiringNow {
                    ProgressBar(progress: CGFloat(program.programProgress ?? 0))
                        .frame(height: 4)
                        .foregroundStyle(Color.jellyfinPurple)
                }
            }
            .padding(10)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(program.isAiringNow ? Color.jellyfinPurple.opacity(0.16) : Color.secondarySystemFill.opacity(0.8))
        }
        .buttonStyle(.plain)
    }

    private var emptyProgramCard: some View {
        Text("No program information")
            .font(.callout)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .padding(.horizontal, EdgeInsets.edgePadding)
            .background(Color.secondarySystemFill.opacity(0.5))
    }

    private func play(channel: ChannelProgram) {
        let channel = playableChannel(for: channel)
        router.route(
            to: .videoPlayer(
                provider: channel.getPlaybackItemProvider(userSession: viewModel.userSession)
            )
        )
    }

    var body: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                if viewModel.hasNoResults {
                    ContentUnavailableView(L10n.noChannels.localizedCapitalized, systemImage: "antenna.radiowaves.left.and.right")
                } else {
                    contentView
                }
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .navigationTitle("Guide")
        .navigationBarTitleDisplayMode(.inline)
        .refreshable {
            viewModel.refresh()
        }
        .onFirstAppear {
            if viewModel.state == .initial {
                viewModel.refresh()
            }
        }
    }
}

private extension BaseItemDto {

    var isAiringNow: Bool {
        guard let startDate, let endDate else { return false }
        return startDate <= .now && endDate >= .now
    }
}

private extension Date {

    var roundedDownToHour: Date {
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour], from: self)
        return Calendar.current.date(from: components) ?? self
    }
}

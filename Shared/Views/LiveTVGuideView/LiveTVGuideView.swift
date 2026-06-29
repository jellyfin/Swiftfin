//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import CollectionVGrid
import Defaults
import JellyfinAPI
import SwiftUI

struct LiveTVGuideView: View {

    @Router
    private var router

    @StateObject
    private var viewModel = GuideViewModel()

    @State
    private var now: Date = .now
    @State
    private var horizontalOffset: CGFloat = 0
    @State
    private var restingOffset: CGFloat = -.greatestFiniteMagnitude

    #if os(tvOS)
    @FocusState
    private var focusedDay: Date?
    #endif

    private let metrics: GuideMetrics = .current
    private let timer = Timer.publish(every: 30, on: .main, in: .common).autoconnect()

    private var gridStart: Date {
        let calendar = Calendar.current
        guard calendar.isDate(viewModel.selectedDay, inSameDayAs: now) else {
            return viewModel.dayStart
        }

        let hourStart = calendar.dateInterval(of: .hour, for: now)?.start ?? viewModel.dayStart
        let minute = calendar.component(.minute, from: now)
        return minute >= 30 ? hourStart.addingTimeInterval(30 * 60) : hourStart
    }

    private var gridEnd: Date {
        viewModel.dayEnd
    }

    private var totalWidth: CGFloat {
        width(from: gridStart, to: gridEnd)
    }

    private var scrollX: CGFloat {
        max(0, restingOffset - horizontalOffset)
    }

    private func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * metrics.pointsPerMinute)
    }

    private func dayLabel(_ day: Date) -> String {
        day.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        content
            .navigationTitle(L10n.guide)
        #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.visible, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    dayMenu
                }
            }
        #endif
            .onReceive(timer) { newValue in
                    now = newValue
                }
                .onFirstAppear {
                    if viewModel.state == .initial {
                        viewModel.send(.refresh)
                    }
                }
    }

    @ViewBuilder
    private var content: some View {
        ZStack {
            switch viewModel.state {
            case .content:
                if viewModel.channels.isEmpty {
                    ContentUnavailableView(L10n.noPrograms.localizedCapitalized, systemImage: "tv")
                } else {
                    loadedView
                }
            case let .error(error):
                ErrorView(error: error)
            case .initial, .refreshing:
                ProgressView()
            }
        }
        .animation(.linear(duration: 0.1), value: viewModel.state)
    }

    @ViewBuilder
    private var loadedView: some View {
        VStack(spacing: 0) {
            #if os(tvOS)
            dayBar
            #endif

            guideView
        }
    }

    @ViewBuilder
    private var guideView: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {

                    headerRow
                        .zIndex(1)

                    channelGrid
                        .zIndex(0)
                }
                .background(horizontalOffsetReader)
            }
            .onPreferenceChange(GuideScrollOffsetKey.self) { value in
                restingOffset = max(restingOffset, value.x)
                horizontalOffset = value.x
            }
            .onChange(of: gridStart) { _ in
                restingOffset = -.greatestFiniteMagnitude
            }
            .onAppear {
                scrollToNow(proxy)
            }
            #if os(tvOS)
            .focusSection()
            #endif
        }
    }

    private var horizontalOffsetReader: some View {
        GeometryReader { proxy in
            Color.clear
                .preference(
                    key: GuideScrollOffsetKey.self,
                    value: proxy.frame(in: .global).origin
                )
        }
    }

    @ViewBuilder
    private var headerRow: some View {
        HStack(spacing: 0) {

            metrics.surface
                .frame(width: metrics.channelColumnWidth, height: metrics.headerHeight)
                .offset(x: scrollX)
                .zIndex(1)

            timeLabels
                .frame(width: totalWidth, height: metrics.headerHeight, alignment: .leading)
                .background(metrics.surface)
                .zIndex(0)
        }
    }

    @ViewBuilder
    private var channelGrid: some View {
        CollectionVGrid(
            uniqueElements: viewModel.channels,
            id: \.id,
            layout: .columns(1, insets: .zero, itemSpacing: 0, lineSpacing: 0)
        ) { channelProgram in
            row(for: channelProgram)
        }
        .onReachedBottomEdge(offset: .offset(300)) {
            viewModel.send(.loadMore)
        }
        .frame(width: metrics.channelColumnWidth + totalWidth)
    }

    @ViewBuilder
    private func row(for channelProgram: ChannelProgram) -> some View {
        HStack(spacing: 0) {

            GuideChannelColumnCell(
                channel: channelProgram.channel,
                width: metrics.channelColumnWidth,
                height: metrics.rowHeight
            )
            .offset(x: scrollX)
            .zIndex(1)

            GuideProgramRow(
                channelProgram: channelProgram,
                metrics: metrics,
                windowStart: gridStart,
                windowEnd: gridEnd,
                now: now,
                onSelect: { play(channelProgram.channel) }
            )
            .zIndex(0)
        }
    }

    @ViewBuilder
    private var timeLabels: some View {
        let count = Int(gridStart.distance(to: gridEnd) / (60 * Double(metrics.interval)))

        HStack(spacing: 0) {
            ForEach(0 ..< max(count, 0), id: \.self) { index in
                let date = gridStart.addingTimeInterval(Double(index * metrics.interval * 60))

                Text(date, style: .time)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
                    .frame(
                        width: CGFloat(metrics.interval) * metrics.pointsPerMinute,
                        alignment: .leading
                    )
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondarySystemFill)
                            .frame(width: 1)
                    }
                    .id("time-\(index)")
            }
        }
    }

    #if os(tvOS)
    @ViewBuilder
    private var dayBar: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: EdgeInsets.edgePadding / 2) {
                ForEach(viewModel.availableDays, id: \.self) { day in
                    DayChip(
                        title: dayLabel(day),
                        isSelected: day == viewModel.selectedDay
                    ) {
                        viewModel.send(.select(day: day))
                    }
                    .focused($focusedDay, equals: day)
                    .id(day)
                }
            }
            .padding(.horizontal, EdgeInsets.edgePadding)
        }
        .focusSection()
        .backport
        .defaultFocus($focusedDay, viewModel.selectedDay)
    }
    #endif

    private var dayMenu: some View {
        Menu {
            ForEach(viewModel.availableDays, id: \.self) { day in
                Button {
                    viewModel.send(.select(day: day))
                } label: {
                    if day == viewModel.selectedDay {
                        Label(dayLabel(day), systemImage: "checkmark")
                    } else {
                        Text(dayLabel(day))
                    }
                }
            }
        } label: {
            Label(dayLabel(viewModel.selectedDay), systemImage: "calendar")
        }
    }

    private func scrollToNow(_ proxy: ScrollViewProxy) {
        #if os(iOS)
        guard viewModel.state == .content,
              Calendar.current.isDateInToday(viewModel.selectedDay) else { return }

        let minutes = max(0, gridStart.distance(to: now) / 60)
        let index = max(0, Int(minutes / Double(metrics.interval)) - 1)

        Task { @MainActor in
            try? await Task.sleep(nanoseconds: 100_000_000)
            withAnimation {
                proxy.scrollTo("time-\(index)", anchor: .leading)
            }
        }
        #endif
    }

    private func play(_ channel: BaseItemDto) {
        guard let userSession = viewModel.userSession else { return }
        router.route(to: .videoPlayer(provider: channel.getPlaybackItemProvider(userSession: userSession)))
    }
}

#if os(tvOS)
private struct DayChip: View {

    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.headline)
                .fontWeight(.semibold)
                .padding(.vertical, 10)
                .padding(.horizontal, 20)
                .if(isSelected) { view in
                    view
                        .background(.white)
                        .foregroundColor(.black)
                }
        }
        .buttonStyle(.card)
        .padding(.horizontal, 4)
        .padding(.vertical)
    }
}
#endif

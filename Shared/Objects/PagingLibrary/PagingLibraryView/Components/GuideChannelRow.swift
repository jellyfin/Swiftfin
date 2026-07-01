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
@_spi(Advanced) import SwiftUIIntrospect

struct GuideChannelRow: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var programsViewModel: PagingLibraryViewModel<ChannelProgramsLibrary>

    let scrollProxy: GuideScrollProxy
    let now: Date
    let baseStart: Date
    let channel: BaseItemDto
    let metrics: GuideMetrics
    let onSelectChannel: () -> Void
    let onSelectProgram: (BaseItemDto) -> Void

    private static let shortThreshold: TimeInterval = 15 * 60

    private var slots: [GuideSlot] {
        GuideSlot.slots(
            from: Array(programsViewModel.displayedElements),
            baseStart: baseStart,
            shortThreshold: Self.shortThreshold
        )
    }

    private func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * metrics.pointsPerMinute)
    }

    var body: some View {
        HStack(spacing: 0) {
            GuideChannelCell(
                channel: channel,
                width: metrics.channelColumnWidth,
                height: metrics.rowHeight,
                action: onSelectChannel
            )

            ScrollView(.horizontal, showsIndicators: false) {
                programStrip
            }
            .introspect(.scrollView, on: .iOS(.v15...), .tvOS(.v15...)) { scrollView in
                scrollProxy.register(
                    scrollView,
                    nowX: width(from: baseStart, to: now),
                    onNearTrailingEdge: {
                        guard !programsViewModel.background.is(.gettingNextPage) else { return }
                        programsViewModel.getNextPage()
                    }
                )
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: metrics.rowHeight,
            maxHeight: metrics.rowHeight,
            alignment: .leading
        )
        .fixedSize(horizontal: false, vertical: true)
        .onFirstAppear {
            if programsViewModel.displayedElements.isEmpty {
                programsViewModel.refresh()
            }
        }
    }

    @ViewBuilder
    private var programStrip: some View {
        let slots = slots

        LazyHStack(spacing: 0) {
            ForEach(Array(slots.enumerated()), id: \.element.id) { index, slot in
                let previousEnd = index == 0 ? baseStart : slots[index - 1].end

                if slot.start > previousEnd {
                    Color.clear
                        .frame(width: width(from: previousEnd, to: slot.start))
                }

                slotCell(slot)
            }
        }
        .frame(height: metrics.rowHeight)
        .overlay(alignment: .leading) {
            Rectangle()
                .fill(accentColor)
                .frame(width: 2, height: metrics.rowHeight)
                .offset(x: width(from: baseStart, to: now))
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func slotCell(_ slot: GuideSlot) -> some View {
        switch slot {
        case let .single(program, start, end):
            GuideProgramCell(
                program: program,
                width: width(from: start, to: end),
                height: metrics.rowHeight,
                now: now,
                action: { onSelectProgram(program) }
            )
        case let .group(programs, start, end):
            GuideProgramMenuCell(
                programs: programs,
                width: width(from: start, to: end),
                height: metrics.rowHeight,
                now: now,
                onSelect: onSelectProgram
            )
        }
    }
}

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

    @ObservedObject
    var scrollProxy: GuideScrollProxy

    let now: Date
    let baseStart: Date
    let channel: BaseItemDto
    let metrics: GuideMetrics
    let onSelectChannel: () -> Void
    let onSelectProgram: (BaseItemDto) -> Void

    private static let shortThreshold: TimeInterval = 15 * 60
    private static let minCellWidth: CGFloat = 25
    private static let windowLeadMargin: CGFloat = 2000
    private static let windowTrailMargin: CGFloat = 4000

    private struct PositionedSlot: Identifiable {
        let slot: GuideSlot
        let x: CGFloat
        let width: CGFloat

        var id: String {
            slot.id
        }
    }

    private var slots: [GuideSlot] {
        GuideSlot.slots(
            from: Array(programsViewModel.displayedElements),
            baseStart: baseStart,
            shortThreshold: Self.shortThreshold
        )
    }

    private var positionedSlots: [PositionedSlot] {
        var result: [PositionedSlot] = []
        var runningX: CGFloat = 0

        for slot in slots {
            let x = max(width(from: baseStart, to: slot.start), runningX)
            let endX = width(from: baseStart, to: slot.end)
            let cellWidth = max(endX - x, Self.minCellWidth)

            result.append(PositionedSlot(slot: slot, x: x, width: cellWidth))
            runningX = x + cellWidth
        }

        return result
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
        let positioned = positionedSlots
        let contentWidth = positioned.last.map { $0.x + $0.width } ?? 0
        let minX = scrollProxy.windowOrigin - Self.windowLeadMargin
        let maxX = scrollProxy.windowOrigin + Self.windowTrailMargin
        let visible = positioned.filter {
            $0.x < maxX && $0.x + $0.width > minX
        }

        ZStack(alignment: .leading) {
            Color.clear
                .frame(width: contentWidth, height: metrics.rowHeight)

            ForEach(visible) { item in
                slotCell(item.slot, width: item.width)
                    .offset(x: item.x)
            }

            Rectangle()
                .fill(accentColor)
                .frame(width: 2, height: metrics.rowHeight)
                .offset(x: width(from: baseStart, to: now))
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func slotCell(_ slot: GuideSlot, width cellWidth: CGFloat) -> some View {
        switch slot {
        case let .single(program, _, _):
            GuideProgramCell(
                program: program,
                width: cellWidth,
                height: metrics.rowHeight,
                now: now,
                action: { onSelectProgram(program) }
            )
        case let .group(programs, _, _):
            GuideProgramMenuCell(
                programs: programs,
                width: cellWidth,
                height: metrics.rowHeight,
                now: now,
                onSelect: onSelectProgram
            )
        }
    }
}

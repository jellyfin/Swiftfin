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

struct GuideChannelRow: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var programsViewModel: PagingLibraryViewModel<ChannelProgramsLibrary>

    @ObservedObject
    var scrollProxy: GuideScrollProxy

    @State
    private var positionedEntries: [PositionedEntry] = []

    let now: Date
    let startDate: Date
    let channel: BaseItemDto
    let layout: GuideLayout
    let channelAction: () -> Void
    let programAction: (BaseItemDto) -> Void

    private static let shortThreshold: TimeInterval = 15 * 60
    private static let minProgramWidth: CGFloat = 50
    private static let windowLeadMargin: CGFloat = 2000
    private static let windowTrailMargin: CGFloat = 4000

    private struct PositionedEntry: Identifiable {
        let entry: GuideEntry
        let x: CGFloat
        let width: CGFloat

        var id: String {
            entry.id
        }
    }

    private func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * layout.pointsPerMinute)
    }

    private func updatePositionedEntries() {
        let entries = GuideEntry.entries(
            from: Array(programsViewModel.displayedElements),
            startDate: startDate,
            shortThreshold: Self.shortThreshold
        )

        var result: [PositionedEntry] = []
        var runningX: CGFloat = 0

        for entry in entries {
            let x = max(width(from: startDate, to: entry.start), runningX)
            let endX = width(from: startDate, to: entry.end)
            let entryWidth = max(endX - x, Self.minProgramWidth)

            result.append(PositionedEntry(entry: entry, x: x, width: entryWidth))
            runningX = x + entryWidth
        }

        positionedEntries = result
    }

    var body: some View {
        HStack(spacing: 0) {
            GuideChannelButton(
                channel: channel,
                width: layout.channelColumnWidth,
                height: layout.rowHeight,
                action: channelAction
            )

            ScrollView(.horizontal, showsIndicators: false) {
                programsView
            }
            .guideScrollSync(
                scrollProxy,
                nowOffset: width(from: startDate, to: now)
            ) {
                guard !programsViewModel.background.is(.gettingNextPage) else { return }
                programsViewModel.getNextPage()
            }
        }
        .frame(
            maxWidth: .infinity,
            minHeight: layout.rowHeight,
            maxHeight: layout.rowHeight,
            alignment: .leading
        )
        .fixedSize(horizontal: false, vertical: true)
        .onFirstAppear {
            updatePositionedEntries()

            if programsViewModel.displayedElements.isEmpty {
                programsViewModel.refresh()
            }
        }
        .backport
        .onChange(of: programsViewModel.displayedElements) {
            updatePositionedEntries()
        }
    }

    @ViewBuilder
    private var programsView: some View {
        let contentWidth = positionedEntries.last.map { $0.x + $0.width } ?? 0
        let minX = scrollProxy.windowOrigin - Self.windowLeadMargin
        let maxX = scrollProxy.windowOrigin + Self.windowTrailMargin
        let visible = positionedEntries.filter {
            $0.x < maxX && $0.x + $0.width > minX
        }

        ZStack(alignment: .leading) {
            Color.clear
                .frame(width: contentWidth, height: layout.rowHeight)

            ForEach(visible) { item in
                entryView(item.entry, width: item.width)
                    .offset(x: item.x)
            }

            Rectangle()
                .fill(accentColor)
                .frame(width: 2, height: layout.rowHeight)
                .offset(x: width(from: startDate, to: now))
                .allowsHitTesting(false)
        }
    }

    @ViewBuilder
    private func entryView(_ entry: GuideEntry, width entryWidth: CGFloat) -> some View {
        switch entry {
        case let .single(program, _, _):
            GuideProgramButton(
                program: program,
                width: entryWidth,
                height: layout.rowHeight,
                now: now,
                action: { programAction(program) }
            )
        case let .group(programs, _, _):
            GuideProgramsMenu(
                programs: programs,
                width: entryWidth,
                height: layout.rowHeight,
                now: now,
                action: programAction
            )
        }
    }
}

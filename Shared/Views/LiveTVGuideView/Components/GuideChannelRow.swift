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

    @ObservedObject
    var guideViewModel: GuideViewModel

    let channel: BaseItemDto
    let layout: GuideLayout
    let playsOnSelect: Bool
    let channelAction: () -> Void
    let programAction: (BaseItemDto) -> Void

    var body: some View {
        RowContent(
            scrollProxy: guideViewModel.scrollProxy,
            entries: guideViewModel.entries[channel.id ?? ""] ?? [],
            now: guideViewModel.now,
            startDate: guideViewModel.startDate,
            endDate: guideViewModel.endDate,
            channel: channel,
            layout: layout,
            isSelected: channel.id != nil && channel.id == guideViewModel.selectedChannelID,
            playsOnSelect: playsOnSelect,
            channelAction: channelAction,
            programAction: programAction
        )
    }
}

extension GuideChannelRow {

    private struct RowContent: View {

        @Default(.accentColor)
        private var accentColor

        let scrollProxy: GuideScrollProxy
        let entries: [GuideEntry.Positioned]
        let now: Date
        let startDate: Date
        let endDate: Date
        let channel: BaseItemDto
        let layout: GuideLayout
        let isSelected: Bool
        let playsOnSelect: Bool
        let channelAction: () -> Void
        let programAction: (BaseItemDto) -> Void

        private func width(from start: Date, to end: Date) -> CGFloat {
            max(0, CGFloat(start.distance(to: end) / 60) * layout.pointsPerMinute)
        }

        var body: some View {
            HStack(spacing: 0) {
                GuideChannelButton(
                    channel: channel,
                    width: layout.channelColumnWidth,
                    height: layout.rowHeight,
                    isSelected: isSelected,
                    playsOnSelect: playsOnSelect,
                    accentColor: accentColor,
                    action: channelAction
                )

                ScrollView(.horizontal, showsIndicators: false) {
                    programsView
                }
                .guideScrollSync(
                    scrollProxy,
                    nowOffset: width(from: startDate, to: now)
                )
            }
            .frame(
                maxWidth: .infinity,
                minHeight: layout.rowHeight,
                maxHeight: layout.rowHeight,
                alignment: .leading
            )
            .fixedSize(horizontal: false, vertical: true)
        }

        @ViewBuilder
        private var programsView: some View {
            let entriesWidth = entries.last.map { $0.x + $0.width } ?? 0
            let contentWidth = max(width(from: startDate, to: endDate), entriesWidth)

            ZStack(alignment: .leading) {
                Color.clear
                    .frame(width: max(contentWidth, 1), height: layout.rowHeight)

                ForEach(entries) { item in
                    entryView(item.entry, width: item.width)
                        .offset(x: item.x)
                }

                if now >= startDate {
                    Rectangle()
                        .fill(accentColor)
                        .frame(width: 2, height: layout.rowHeight)
                        .offset(x: width(from: startDate, to: now))
                        .allowsHitTesting(false)
                }
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
                    playsOnSelect: playsOnSelect,
                    accentColor: accentColor,
                    action: { programAction(program) }
                )
            case let .group(programs, _, _):
                GuideProgramsMenu(
                    programs: programs,
                    width: entryWidth,
                    height: layout.rowHeight,
                    now: now,
                    playsOnSelect: playsOnSelect,
                    accentColor: accentColor,
                    action: programAction
                )
            }
        }
    }
}

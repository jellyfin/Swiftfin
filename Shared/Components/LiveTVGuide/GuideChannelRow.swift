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
    let programAction: (BaseItemDto) -> Void

    var body: some View {
        RowContent(
            scrollProxy: guideViewModel.scrollProxy,
            entries: guideViewModel.entries[channel.id ?? ""] ?? [],
            now: guideViewModel.now,
            startDate: guideViewModel.startDate,
            endDate: guideViewModel.endDate,
            layout: layout,
            playsOnSelect: playsOnSelect,
            programAction: programAction
        )
    }
}

extension GuideChannelRow {

    private struct RowContent: View {

        @Default(.accentColor)
        private var accentColor

        @ObservedObject
        var scrollProxy: GuideScrollProxy

        let entries: [GuideEntry.Positioned]
        let now: Date
        let startDate: Date
        let endDate: Date
        let layout: GuideLayout
        let playsOnSelect: Bool
        let programAction: (BaseItemDto) -> Void

        private func width(from start: Date, to end: Date) -> CGFloat {
            max(0, CGFloat(start.distance(to: end) / 60) * layout.pointsPerMinute)
        }

        var body: some View {
            let contentWidth = max(width(from: startDate, to: endDate), 1)
            let window = scrollProxy.visibleWindow
            let visibleEntries = entries.filter {
                $0.x < window.upperBound && $0.x + $0.width > window.lowerBound
            }

            ZStack(alignment: .leading) {
                Color.clear
                    .frame(width: contentWidth, height: layout.rowHeight)

                ForEach(visibleEntries) { item in
                    entryView(item)
                        .offset(x: item.x)
                }
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
        private func entryView(_ item: GuideEntry.Positioned) -> some View {
            switch item.entry {
            case let .single(program, _, _):
                GuideProgramButton(
                    program: program,
                    width: item.width,
                    height: layout.rowHeight,
                    now: now,
                    playsOnSelect: playsOnSelect,
                    accentColor: accentColor,
                    action: { programAction(program) }
                )
            case let .group(programs, _, _):
                GuideProgramsMenu(
                    programs: programs,
                    width: item.width,
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

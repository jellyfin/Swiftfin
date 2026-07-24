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
    var viewModel: GuideViewModel

    let channel: BaseItemDto
    let onSelect: (BaseItemDto) -> Void

    var body: some View {
        RowContent(
            proxy: viewModel.proxy,
            entries: viewModel.entries[channel.id ?? ""] ?? [],
            now: viewModel.now,
            startDate: viewModel.startDate,
            endDate: viewModel.endDate,
            onSelect: onSelect
        )
    }
}

extension GuideChannelRow {

    private struct RowContent: View {

        @Default(.accentColor)
        private var accentColor

        private let layout = LiveTVGuideLayout()

        @ObservedObject
        var proxy: LiveTVGuideProxy

        let entries: [LiveTVGuideProgram.Positioned]
        let now: Date
        let startDate: Date
        let endDate: Date
        let onSelect: (BaseItemDto) -> Void

        var body: some View {
            let contentWidth = max(layout.width(from: startDate, to: endDate), 1)
            let window = proxy.visibleWindow
            let visibleEntries = entries.filter {
                $0.x < window.upperBound && $0.x + $0.width > window.lowerBound
            }

            ZStack(alignment: .leading) {
                Color.clear
                    .frame(width: contentWidth, height: layout.rowHeight)

                ForEach(visibleEntries) { positioned in
                    cell(positioned)
                        .offset(x: positioned.x)
                }
            }
            .frame(
                maxWidth: .infinity,
                minHeight: layout.rowHeight,
                maxHeight: layout.rowHeight,
                alignment: .leading
            )
            .fixedSize(horizontal: false, vertical: true)
            .tint(accentColor)
        }

        @ViewBuilder
        private func cell(_ positioned: LiveTVGuideProgram.Positioned) -> some View {
            GuideProgramCell(
                entry: positioned.entry,
                width: positioned.width,
                now: now,
                onSelect: onSelect
            )
        }
    }
}

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

struct GuideProgramRow: View {

    @Default(.accentColor)
    private var accentColor

    let channelProgram: ChannelProgram
    let metrics: GuideMetrics
    let windowStart: Date
    let windowEnd: Date
    let now: Date
    let onSelect: () -> Void

    private var totalWidth: CGFloat {
        width(from: windowStart, to: windowEnd)
    }

    private func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * metrics.pointsPerMinute)
    }

    var body: some View {
        let items = GuideRowItem.build(
            programs: channelProgram.programs,
            windowStart: windowStart,
            windowEnd: windowEnd
        )

        Group {
            if items.isEmpty {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.secondarySystemFill.opacity(0.15))
                    .overlay {
                        Text(L10n.noPrograms.localizedCapitalized)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .overlay {
                        RoundedRectangle(cornerRadius: 8)
                            .strokeBorder(Color.secondarySystemFill.opacity(0.5), lineWidth: 1)
                    }
                    .padding(4)
            } else {
                rowContent(items)
            }
        }
        .frame(width: totalWidth, height: metrics.rowHeight, alignment: .leading)
        .overlay(alignment: .leading) {
            if now >= windowStart, now <= windowEnd {
                Rectangle()
                    .fill(accentColor)
                    .frame(width: 2)
                    .offset(x: width(from: windowStart, to: now))
                    .allowsHitTesting(false)
            }
        }
    }

    @ViewBuilder
    private func rowContent(_ items: [GuideRowItem]) -> some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                switch item {
                case .gap:
                    Color.clear
                        .frame(width: width(from: item.start, to: item.end))
                case let .segment(segment):
                    cell(for: segment)
                }
            }
        }
    }

    @ViewBuilder
    private func cell(for segment: GuideSegment) -> some View {
        GuideProgramButton(
            segment: segment,
            width: width(from: segment.start, to: segment.end),
            height: metrics.rowHeight,
            now: now,
            action: { _ in onSelect() }
        )
    }
}

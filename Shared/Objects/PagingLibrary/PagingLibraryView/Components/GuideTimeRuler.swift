//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct GuideTimeRuler: View {

    let scrollProxy: GuideScrollProxy
    let startDate: Date
    let now: Date
    let layout: GuideLayout

    private static let intervalMinutes = 30
    private static let rulerDays = 7
    private static let labelCount = (24 * 60 / intervalMinutes) * rulerDays

    private func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * layout.pointsPerMinute)
    }

    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: layout.channelColumnWidth)

            ScrollView(.horizontal, showsIndicators: false) {
                labels
            }
            .guideScrollSync(
                scrollProxy,
                nowOffset: width(from: startDate, to: now)
            )
        }
        .frame(height: layout.rulerHeight)
    }

    @ViewBuilder
    private var labels: some View {
        LazyHStack(spacing: 0) {
            ForEach(0 ..< Self.labelCount, id: \.self) { index in
                let date = startDate.addingTimeInterval(Double(index * Self.intervalMinutes * 60))

                label(for: date)
                    .frame(width: CGFloat(Self.intervalMinutes) * layout.pointsPerMinute, alignment: .leading)
                    .overlay(alignment: .leading) {
                        Rectangle()
                            .fill(Color.secondarySystemFill)
                            .frame(width: 1)
                    }
            }
        }
    }

    @ViewBuilder
    private func label(for date: Date) -> some View {
        let components = Calendar.current.dateComponents([.hour, .minute], from: date)
        let isDayStart = components.hour == 0 && components.minute == 0

        Text(
            isDayStart
                ? date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
                : date.formatted(date: .omitted, time: .shortened)
        )
        .font(.caption2.weight(.semibold))
        .foregroundStyle(isDayStart ? Color.primary : Color.secondary)
        .lineLimit(1)
        .padding(.leading, 4)
    }
}

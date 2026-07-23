//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct GuideTimeRuler: View {

    let startDate: Date
    let endDate: Date
    let layout: GuideLayout

    private static let intervalMinutes = 30

    private var labelCount: Int {
        max(0, Int(startDate.distance(to: endDate) / (Double(Self.intervalMinutes) * 60)))
    }

    var body: some View {
        LazyHStack(spacing: 0) {
            ForEach(0 ..< labelCount, id: \.self) { index in
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
        .frame(height: layout.rulerHeight)
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

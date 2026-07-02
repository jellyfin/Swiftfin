//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct GuideTimeRuler: View {

    let scrollProxy: GuideScrollProxy
    let baseStart: Date
    let now: Date
    let metrics: GuideMetrics

    private static let intervalMinutes = 30
    private static let slotCount = 48 * 14

    private func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * metrics.pointsPerMinute)
    }

    var body: some View {
        HStack(spacing: 0) {
            Color.clear
                .frame(width: metrics.channelColumnWidth)

            ScrollView(.horizontal, showsIndicators: false) {
                labels
            }
            .introspect(.scrollView, on: .iOS(.v15...), .tvOS(.v15...)) { scrollView in
                #if os(tvOS)
                scrollView.contentInsetAdjustmentBehavior = .never
                #endif
                scrollProxy.register(
                    scrollView,
                    nowX: width(from: baseStart, to: now),
                    onNearTrailingEdge: {}
                )
            }
        }
        .frame(height: metrics.rulerHeight)
    }

    @ViewBuilder
    private var labels: some View {
        LazyHStack(spacing: 0) {
            ForEach(0 ..< Self.slotCount, id: \.self) { index in
                let date = baseStart.addingTimeInterval(Double(index * Self.intervalMinutes * 60))

                label(for: date)
                    .frame(width: CGFloat(Self.intervalMinutes) * metrics.pointsPerMinute, alignment: .leading)
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

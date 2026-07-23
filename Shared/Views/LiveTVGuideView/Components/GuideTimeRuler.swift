//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct GuideTimeRuler: View {

    @Default(.accentColor)
    private var accentColor

    let scrollProxy: GuideScrollProxy
    let startDate: Date
    let endDate: Date
    let now: Date
    let layout: GuideLayout

    private static let intervalMinutes = 30

    private var labelCount: Int {
        max(0, Int(startDate.distance(to: endDate) / (Double(Self.intervalMinutes) * 60)))
    }

    private func width(from start: Date, to end: Date) -> CGFloat {
        max(0, CGFloat(start.distance(to: end) / 60) * layout.pointsPerMinute)
    }

    var body: some View {
        HStack(spacing: 0) {
            ZStack {
                if now >= startDate {
                    OnNowButton {
                        scrollProxy.scrollTo(centering: width(from: startDate, to: now))
                    }
                }
            }
            .frame(width: layout.channelColumnWidth)

            ScrollView(.horizontal, showsIndicators: false) {
                ZStack(alignment: .leading) {
                    labels

                    if now >= startDate {
                        Rectangle()
                            .fill(accentColor)
                            .frame(width: 2)
                            .offset(x: width(from: startDate, to: now))
                            .allowsHitTesting(false)
                    }
                }
            }
            .guideScrollSync(
                scrollProxy,
                nowOffset: width(from: startDate, to: now)
            )
        }
        .frame(height: layout.rulerHeight)
        #if os(tvOS)
            .focusSection()
        #endif
    }

    @ViewBuilder
    private var labels: some View {
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

extension GuideTimeRuler {

    private struct OnNowButton: View {

        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Content()
            }
            .buttonStyle(GuideButtonStyle())
            #if os(tvOS)
                .focusEffectDisabled()
            #endif
        }
    }

    private struct Content: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isFocused)
        private var isFocused

        var body: some View {
            Text(L10n.onNow)
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .backport
                .glassEffect(
                    .regular.selection(
                        tint: isFocused ? accentColor : nil,
                        foregroundColor: isFocused ? accentColor.overlayColor : .primary
                    ),
                    in: .capsule
                )
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct GuideDateBar: View {

    @ObservedObject
    var viewModel: GuideViewModel

    private var selectedDate: Date {
        max(viewModel.startDate, Calendar.current.startOfDay(for: .now))
    }

    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    var body: some View {
        HStack(spacing: 16) {
            ForEach(viewModel.availableDates, id: \.self) { date in
                DatePill(
                    title: date.formatted(.dateTime.weekday(.abbreviated).day()),
                    isSelected: isSelected(date)
                ) {
                    viewModel.setDate(date: date)
                }
            }
        }
        #if os(tvOS)
        .focusSection()
        #endif
    }
}

extension GuideDateBar {

    private struct DatePill: View {

        let title: String
        let isSelected: Bool
        let action: () -> Void

        var body: some View {
            Button(action: action) {
                Content(
                    title: title,
                    isSelected: isSelected
                )
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

        let title: String
        let isSelected: Bool

        private var tint: Color? {
            if isFocused {
                accentColor
            } else if isSelected {
                accentColor.opacity(0.5)
            } else {
                nil
            }
        }

        var body: some View {
            Text(title)
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
                .frame(
                    width: UIDevice.isTV ? 150 : 110,
                    height: UIDevice.isTV ? 44 : 36
                )
                .backport
                .glassEffect(
                    .regular.selection(
                        tint: tint,
                        foregroundColor: isFocused ? accentColor.overlayColor : .primary
                    )
                    .interactive(false),
                    in: .capsule
                )
        }
    }
}

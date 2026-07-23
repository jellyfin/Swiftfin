//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct GuideDateMenu: View {

    @ObservedObject
    var viewModel: GuideViewModel

    private var selectedDate: Date {
        max(viewModel.startDate, Calendar.current.startOfDay(for: .now))
    }

    private func isSelected(_ date: Date) -> Bool {
        Calendar.current.isDate(date, inSameDayAs: selectedDate)
    }

    var body: some View {
        #if os(tvOS)
        HStack(spacing: 8) {
            ForEach(viewModel.availableDates, id: \.self) { date in
                DatePill(
                    title: date.formatted(.dateTime.weekday(.abbreviated).day()),
                    isSelected: isSelected(date)
                ) {
                    viewModel.select(date: date)
                }
            }
        }
        #else
        Menu {
            ForEach(viewModel.availableDates, id: \.self) { date in
                Button {
                    viewModel.select(date: date)
                } label: {
                    if isSelected(date) {
                        Label(label(for: date), systemImage: "checkmark")
                    } else {
                        Text(label(for: date))
                    }
                }
            }
        } label: {
            Label(label(for: selectedDate), systemImage: "calendar")
        }
        #endif
    }

    private func label(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }
}

extension GuideDateMenu {

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
                .font(.caption2.weight(.semibold))
                .lineLimit(1)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .backport
                .glassEffect(
                    .regular.selection(
                        tint: tint,
                        foregroundColor: isFocused ? accentColor.overlayColor : .primary
                    ),
                    in: .capsule
                )
        }
    }
}

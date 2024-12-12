//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

extension EditAccessScheduleView {

    struct EditAccessScheduleRow: View {

        // MARK: - Environment Variables

        @Environment(\.isEditing)
        var isEditing
        @Environment(\.isSelected)
        var isSelected

        // MARK: - Schedule Variable

        let schedule: AccessSchedule

        // MARK: - Schedule Actions

        let onSelect: () -> Void
        let onDelete: () -> Void

        // MARK: - Body

        var body: some View {
            ListRow {} content: {
                rowContent
            }
            .onSelect(perform: onSelect)
            .isSeparatorVisible(false)
            .swipeActions {
                Button(L10n.delete, systemImage: "trash", action: onDelete)
                    .tint(.red)
            }
        }

        // MARK: - Row Content

        @ViewBuilder
        private var rowContent: some View {
            HStack {
                VStack(alignment: .leading) {
                    if let dayOfWeek = schedule.dayOfWeek {
                        Text(dayOfWeek.rawValue)
                            .font(.headline)
                    }
                    if let startHour = schedule.startHour {
                        TextPairView(
                            leading: L10n.startTime,
                            trailing: doubleToTimeString(startHour)
                        )
                        .font(.subheadline)
                    }
                    if let endHour = schedule.endHour {
                        TextPairView(
                            leading: L10n.endTime,
                            trailing: doubleToTimeString(endHour)
                        )
                        .font(.subheadline)
                    }
                }
                .foregroundStyle(
                    isEditing ? (isSelected ? .primary : .secondary) : .primary,
                    .secondary
                )

                Spacer()

                ListRowCheckbox()
            }
        }

        // MARK: - Convert Double to Date

        private func doubleToTimeString(_ double: Double) -> String {
            let startHours = Int(double)
            let startMinutes = Int(double.truncatingRemainder(dividingBy: 1) * 60)

            var dateComponents = DateComponents()
            dateComponents.hour = startHours
            dateComponents.minute = startMinutes

            let calendar = Calendar.current

            guard let date = calendar.date(from: dateComponents) else {
                return .emptyTime
            }

            let formatter = DateFormatter()
            formatter.timeStyle = .short

            return formatter.string(from: date)
        }
    }
}

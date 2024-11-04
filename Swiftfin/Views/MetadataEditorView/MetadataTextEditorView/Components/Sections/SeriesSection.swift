//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Combine
import JellyfinAPI
import SwiftUI

extension MetadataTextEditorView {
    struct SeriesSection: View {
        @Binding
        var item: BaseItemDto

        @State
        private var tempTimeInterval: TimeInterval = 0
        @State
        private var tempRunTime: Int?

        // MARK: - Initializer

        init(item: Binding<BaseItemDto>) {
            self._item = Binding(projectedValue: item)
            self.tempRunTime = Int(ServerTicks(item.wrappedValue.runTimeTicks ?? 0).minutes)
        }

        // MARK: - Body

        var body: some View {
            Section(L10n.series) {
                Picker("Status", selection: Binding(get: {
                    item.status ?? ""
                }, set: {
                    item.status = $0
                })) {
                    Text("Continuing").tag("Continuing")
                    Text("Ended").tag("Ended")
                    Text("Unreleased").tag("Unreleased")
                }
            }

            Section(L10n.episodes) {
                DatePicker(
                    "Air Time",
                    selection: Binding<Date>(
                        get: { parseAirTimeToDate(item.airTime) },
                        set: { date in
                            item.airTime = formatDateToString(date)
                        }
                    ),
                    displayedComponents: .hourAndMinute
                )
                ChevronAlertButton(
                    "Run Time",
                    subtitle: ServerTicks(item.runTimeTicks ?? 0)
                        .seconds.formatted(.hourMinute),
                    description: "Episode runtime in minutes"
                ) {
                    TextField(
                        "Minutes",
                        value: $tempRunTime,
                        format: .number
                    )
                    .keyboardType(.numberPad)
                } onSave: {
                    if let tempRunTime = tempRunTime, tempRunTime != 0 {
                        item.runTimeTicks = ServerTicks(minutes: tempRunTime).ticks
                    } else {
                        item.runTimeTicks = nil
                    }
                } onCancel: {
                    if let originalRunTime = item.runTimeTicks {
                        tempRunTime = Int(ServerTicks(originalRunTime).minutes)
                    } else {
                        tempRunTime = nil
                    }
                }
            }
        }

        // MARK: - Parse AirTime to Date

        private func parseAirTimeToDate(_ airTime: String?) -> Date {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            if let airTime = airTime, let date = dateFormatter.date(from: airTime) {
                return date
            }
            return dateFormatter.date(from: "00:00") ?? Date()
        }

        // MARK: - Format Date to String

        private func formatDateToString(_ date: Date) -> String {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "HH:mm"
            return dateFormatter.string(from: date)
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct GuideDateMenu: View {

    @ObservedObject
    var viewModel: GuideViewModel

    private var selectedDate: Date {
        max(viewModel.startDate, Calendar.current.startOfDay(for: .now))
    }

    private func label(for date: Date) -> String {
        date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day())
    }

    var body: some View {
        Menu {
            ForEach(viewModel.availableDates, id: \.self) { date in
                Button {
                    viewModel.select(date: date)
                } label: {
                    if Calendar.current.isDate(date, inSameDayAs: selectedDate) {
                        Label(label(for: date), systemImage: "checkmark")
                    } else {
                        Text(label(for: date))
                    }
                }
            }
        } label: {
            Label(label(for: selectedDate), systemImage: "calendar")
        }
    }
}

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

    private var selection: Binding<Date> {
        Binding(
            get: {
                max(
                    Calendar.current.startOfDay(for: viewModel.startDate),
                    Calendar.current.startOfDay(for: .now)
                )
            },
            set: {
                viewModel.setDate(date: $0)
            }
        )
    }

    var body: some View {
        Menu(L10n.date, systemImage: "calendar") {
            Picker(L10n.date, selection: selection) {
                ForEach(viewModel.availableDates, id: \.self) { date in
                    Text(date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                        .tag(date)
                }
            }
        }
    }
}

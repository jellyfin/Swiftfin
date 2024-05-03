//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import MultiComponentPicker
import SwiftUI

// TODO: localize
//       - can DateFormatter do it automagically?

struct HourMinutePicker: View {

    @State
    private var componentHourSelection: Int
    @State
    private var componentMinuteSelection: Int

    private let duration: Binding<TimeInterval>

    init(
        duration: Binding<TimeInterval>
    ) {
        self.duration = duration

        _componentHourSelection = State(initialValue: Int(duration.wrappedValue) / 3600)
        _componentMinuteSelection = State(initialValue: (Int(duration.wrappedValue) % 3600) / 60)
    }

    var body: some View {
        MultiComponentPicker {
            ComponentPickerItem(
                selection: $componentHourSelection,
                values: Array(0 ... 23)
            ) { value in
                Group {
                    if value == 1 {
                        Text("hour")
                            .fontWeight(.bold)
                    } else {
                        Text("hours")
                            .fontWeight(.bold)
                            .transition(.opacity)
                    }
                }
                .padding(.leading, 8)
            }

            ComponentPickerItem(
                selection: $componentMinuteSelection,
                values: Array(0 ... 59)
            ) { _ in
                Text("min")
                    .fontWeight(.bold)
                    .padding(.leading, 8)
            }
        }
        .onChange(of: componentHourSelection) { newValue in
            let newDuration = Double(newValue * 3600 + componentMinuteSelection * 60)
            duration.wrappedValue = newDuration
        }
        .onChange(of: componentMinuteSelection) { newValue in
            let newDuration = Double(componentHourSelection * 3600 + newValue * 60)
            duration.wrappedValue = newDuration
        }
    }
}

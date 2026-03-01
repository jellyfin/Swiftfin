//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI
import TVOSPicker

struct HourMinutePicker: UIViewRepresentable {

    @Default(.backgroundSignOutInterval)
    private var backgroundSignOutInterval

    func makeUIView(context: Context) -> some UIView {
        let picker = TVOSPickerView(
            style: .default // pass custom style here if needed
        )

        context.coordinator.add(picker: picker)

        // Defaults doesn't provide a binding so utilize a callback
        context.coordinator.callback = { interval in
            backgroundSignOutInterval = interval
        }

        return picker
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(previousInterval: backgroundSignOutInterval)
    }

    class Coordinator: TVOSPickerViewDelegate {
        // callback to set the value to defaults
        var callback: ((TimeInterval) -> Void)?

        // selected values
        private var selectedHour: TimeInterval = 0
        private var selectedMinute: TimeInterval = 0

        // previousInterval helps set the default values of the picker
        private let previousInterval: TimeInterval

        init(previousInterval: TimeInterval) {
            self.previousInterval = previousInterval
        }

        func add(picker: TVOSPickerView) {
            picker.delegate = self
        }

        func numberOfComponents(in pickerView: TVOSPickerView) -> Int {
            // number of components (columns)
            2
        }

        func pickerView(_ pickerView: TVOSPickerView, numberOfRowsInComponent component: Int) -> Int {
            // number of rows in each component
            if component == 0 {
                24 // hours
            } else {
                60 // mintues
            }
        }

        func pickerView(_ pickerView: TVOSPickerView, titleForRow row: Int, inComponent component: Int) -> String? {
            // string to display in each row
            if component == 0 {
                "\(row) \(L10n.hours)"
            } else {
                "\(row) \(L10n.minutes)"
            }
        }

        func pickerView(_ pickerView: TVOSPickerView, didSelectRow row: Int, inComponent component: Int) {
            // update state with the newly selected row

            if component == 0 {
                selectedHour = Double(row * 3600)
            } else {
                selectedMinute = Double(row * 60)
            }

            callback?(selectedHour + selectedMinute)
        }

        func indexOfSelectedRow(inComponent component: Int, ofPickerView pickerView: TVOSPickerView) -> Int? {
            // provide an index of selected row - used as initially focused index as well as after each reloadData
            if component == 0 {
                Int(previousInterval) / 3600 // select the previous hour
            } else {
                (Int(previousInterval) / 60) % 60 // select the previous minute
            }
        }
    }
}

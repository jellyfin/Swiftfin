//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if os(tvOS)
import TVOSPicker
#endif

struct HourMinutePicker: View {

    @State
    private var isPresented = false

    private let title: String
    private let interval: Binding<TimeInterval>

    init(_ title: String, interval: Binding<TimeInterval>) {
        self.title = title
        self.interval = interval
    }

    @ViewBuilder
    var body: some View {
        ChevronButton(
            title,
            subtitle: Text(Duration.seconds(interval.wrappedValue), format: .hourMinuteAbbreviated)
        ) {
            isPresented.toggle()
        }
        #if os(tvOS)
        ._alert(title, isPresented: $isPresented) {
            _HourMinutePickerView(interval: interval)
        }
        #endif

        #if !os(tvOS)
        if isPresented {
            _HourMinutePickerView(interval: interval)
        }
        #endif
    }
}

// MARK: - iOS Picker

#if os(iOS)

private struct _HourMinutePickerView: UIViewRepresentable {

    let interval: Binding<TimeInterval>

    func makeUIView(context: Context) -> some UIView {
        let picker = UIDatePicker(frame: .zero)
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.datePickerMode = .countDownTimer
        picker.countDownDuration = interval.wrappedValue

        context.coordinator.add(picker: picker)
        context.coordinator.interval = interval

        return picker
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {

        var interval: Binding<TimeInterval>!

        func add(picker: UIDatePicker) {
            picker.addTarget(
                self,
                action: #selector(
                    dateChanged
                ),
                for: .valueChanged
            )
        }

        @objc
        func dateChanged(_ picker: UIDatePicker) {
            interval.wrappedValue = picker.countDownDuration
        }
    }
}

#endif

// MARK: - tvOS Picker

#if os(tvOS)

private struct _HourMinutePickerView: UIViewRepresentable {

    let interval: Binding<TimeInterval>

    func makeUIView(context: Context) -> some UIView {
        let picker = TVOSPickerView(
            style: .default
        )

        context.coordinator.add(picker: picker)

        context.coordinator.callback = { newValue in
            self.interval.wrappedValue = newValue
        }

        return picker
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(previousInterval: interval.wrappedValue)
    }

    class Coordinator: TVOSPickerViewDelegate {
        var callback: ((TimeInterval) -> Void)?

        private var selectedHour: TimeInterval = 0
        private var selectedMinute: TimeInterval = 0

        private let previousInterval: TimeInterval

        init(previousInterval: TimeInterval) {
            self.previousInterval = previousInterval
        }

        func add(picker: TVOSPickerView) {
            picker.delegate = self
        }

        func numberOfComponents(in pickerView: TVOSPickerView) -> Int {
            2
        }

        func pickerView(_ pickerView: TVOSPickerView, numberOfRowsInComponent component: Int) -> Int {
            if component == 0 {
                24
            } else {
                60
            }
        }

        func pickerView(_ pickerView: TVOSPickerView, titleForRow row: Int, inComponent component: Int) -> String? {
            if component == 0 {
                "\(row) \(L10n.hours)"
            } else {
                "\(row) \(L10n.minutes)"
            }
        }

        func pickerView(_ pickerView: TVOSPickerView, didSelectRow row: Int, inComponent component: Int) {
            if component == 0 {
                selectedHour = Double(row * 3600)
            } else {
                selectedMinute = Double(row * 60)
            }

            callback?(selectedHour + selectedMinute)
        }

        func indexOfSelectedRow(inComponent component: Int, ofPickerView pickerView: TVOSPickerView) -> Int? {
            if component == 0 {
                Int(previousInterval) / 3600
            } else {
                (Int(previousInterval) / 60) % 60
            }
        }
    }
}

#endif

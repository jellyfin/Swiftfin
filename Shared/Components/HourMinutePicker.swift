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

    let title: String
    let interval: Binding<TimeInterval>

    /// `UIDatePicker` cannot exceed 23 hours, a larger maximum falls back to a plain hour/minute picker
    var maximumHours: Int = 24
    /// Style shown in place of a zero interval
    var noneStyle: NoneStyle?

    private var content: String {
        if interval.wrappedValue == 0, let noneStyle {
            noneStyle.displayTitle
        } else {
            Duration.seconds(interval.wrappedValue).formatted(.hourMinuteAbbreviated)
        }
    }

    var body: some View {
        ChevronButton(
            title,
            content: content
        ) {
            isPresented.toggle()
        }
        #if os(tvOS)
        ._alert(title, isPresented: $isPresented) {
            _HourMinutePickerView(interval: interval, maximumHours: maximumHours)
        }
        #endif

        #if !os(tvOS)
        if isPresented {
            _HourMinutePickerView(interval: interval, maximumHours: maximumHours)
        }
        #endif
    }
}

// MARK: - iOS Picker

#if os(iOS)

private struct _HourMinutePickerView: PlatformViewRepresentable {

    private let interval: Binding<TimeInterval>
    private let maximumHours: Int

    init(interval: Binding<TimeInterval>, maximumHours: Int = 24) {
        self.interval = interval
        self.maximumHours = maximumHours
    }

    func makeUIView(context: Context) -> UIView {
        context.coordinator.interval = interval

        guard maximumHours > 24 else {
            let picker = UIDatePicker(frame: .zero)
            picker.translatesAutoresizingMaskIntoConstraints = false
            picker.datePickerMode = .countDownTimer
            picker.countDownDuration = interval.wrappedValue

            context.coordinator.add(picker: picker)

            return picker
        }

        let picker = UIPickerView(frame: .zero)
        picker.translatesAutoresizingMaskIntoConstraints = false
        picker.dataSource = context.coordinator
        picker.delegate = context.coordinator

        let minutes = Int(interval.wrappedValue / 60)
        picker.selectRow(minutes / 60, inComponent: 0, animated: false)
        picker.selectRow(minutes % 60, inComponent: 1, animated: false)

        return picker
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(maximumHours: maximumHours)
    }

    class Coordinator: NSObject, UIPickerViewDataSource, UIPickerViewDelegate {

        var interval: Binding<TimeInterval>!

        private let maximumHours: Int

        init(maximumHours: Int) {
            self.maximumHours = maximumHours
        }

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

        func numberOfComponents(in pickerView: UIPickerView) -> Int {
            2
        }

        func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
            if component == 0 {
                maximumHours
            } else {
                60
            }
        }

        func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
            if component == 0 {
                "\(row) \(L10n.hours)"
            } else {
                "\(row) \(L10n.minutes)"
            }
        }

        func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
            let hours = pickerView.selectedRow(inComponent: 0)
            let minutes = pickerView.selectedRow(inComponent: 1)

            interval.wrappedValue = TimeInterval(hours * 3600 + minutes * 60)
        }
    }
}

// MARK: - tvOS Picker

#elseif os(tvOS)

private struct _HourMinutePickerView: PlatformViewRepresentable {

    private let interval: Binding<TimeInterval>
    private let maximumHours: Int

    init(interval: Binding<TimeInterval>, maximumHours: Int = 24) {
        self.interval = interval
        self.maximumHours = maximumHours
    }

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
        Coordinator(
            previousInterval: interval.wrappedValue,
            maximumHours: maximumHours
        )
    }

    class Coordinator: TVOSPickerViewDelegate {
        var callback: ((TimeInterval) -> Void)?

        private var selectedHour: TimeInterval = 0
        private var selectedMinute: TimeInterval = 0

        private let previousInterval: TimeInterval
        private let maximumHours: Int

        init(previousInterval: TimeInterval, maximumHours: Int) {
            self.previousInterval = previousInterval
            self.maximumHours = maximumHours
        }

        func add(picker: TVOSPickerView) {
            picker.delegate = self
        }

        func numberOfComponents(in pickerView: TVOSPickerView) -> Int {
            2
        }

        func pickerView(_ pickerView: TVOSPickerView, numberOfRowsInComponent component: Int) -> Int {
            if component == 0 {
                maximumHours
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

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CustomAlertPicker<Value: CaseIterable & Displayable & Hashable & RawRepresentable & Storable, CustomContent: View>: View
where Value.RawValue: Equatable {

    @State
    private var customValue: Value
    @State
    private var isPresentingCustomValue: Bool = false

    private let title: String
    private let selection: Binding<Value>
    private let customTitle: String
    private let customDescription: String
    private let customContent: (Binding<Value>) -> CustomContent

    init(
        title: String,
        selection: Binding<Value>,
        customTitle: String,
        customDescription: String,
        @ViewBuilder customContent: @escaping (Binding<Value>) -> CustomContent
    ) {
        self._customValue = State(initialValue: selection.wrappedValue)
        self.title = title
        self.selection = selection
        self.customTitle = customTitle
        self.customDescription = customDescription
        self.customContent = customContent
    }

    private func matchingPreset(for value: Value) -> Value? {
        Value.allCases.first { $0.rawValue == value.rawValue }
    }

    private var pickerSelection: Binding<Value?> {
        Binding(
            get: { matchingPreset(for: selection.wrappedValue) ?? selection.wrappedValue },
            set: { value in
                if let value {
                    selection.wrappedValue = value
                } else {
                    customValue = selection.wrappedValue
                    isPresentingCustomValue = true
                }
            }
        )
    }

    private var picker: some View {
        Picker(title, selection: pickerSelection) {
            ForEach(Value.allCases.asArray, id: \.self) { value in
                Text(value.displayTitle)
                    .tag(value as Value?)
            }

            if matchingPreset(for: selection.wrappedValue) == nil {
                Text(selection.wrappedValue.displayTitle)
                    .tag(selection.wrappedValue as Value?)
            }

            Divider()

            Text(L10n.custom)
                .tag(nil as Value?)
        } currentValueLabel: {
            Text(selection.wrappedValue.displayTitle)
        }
    }

    @ViewBuilder
    private var content: some View {
        #if os(tvOS)
        ListRowMenu(title, subtitle: Text(selection.wrappedValue.displayTitle)) {
            picker
        }
        #else
        picker
        #endif
    }

    var body: some View {
        content
            .alert(customTitle, isPresented: $isPresentingCustomValue) {
                customContent($customValue)

                Button(L10n.cancel, role: .cancel) {}

                Button(L10n.ok) {
                    selection.wrappedValue = matchingPreset(for: customValue) ?? customValue
                }
            } message: {
                Text(customDescription)
            }
    }
}

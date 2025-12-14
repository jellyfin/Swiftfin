//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - Picker Overloads

func Picker<SelectionValue, Content, InputContent>(
    _ title: String,
    selection: Binding<SelectionValue>,
    currentValue: String? = nil,
    isCustom: @escaping (SelectionValue) -> Bool,
    customTag: SelectionValue,
    customDefault: @escaping (SelectionValue) -> SelectionValue,
    customDescription: String? = nil,
    onCancelValue: SelectionValue? = nil,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder customInput: @escaping (Binding<SelectionValue>) -> InputContent,
) -> some View where SelectionValue: Hashable & Equatable & Displayable, Content: View, InputContent: View {
    InputPicker(
        title: title,
        selection: selection,
        isCustom: isCustom,
        customTag: customTag,
        customDefault: customDefault,
        customDescription: customDescription,
        onCancelValue: onCancelValue,
        content: content,
        currentValueLabel: {
            if let currentValue {
                Text(currentValue)
            } else {
                EmptyView()
            }
        },
        customInput: customInput
    )
}

func Picker<SelectionValue, Content, InputContent, CurrentValueLabel>(
    _ title: String,
    selection: Binding<SelectionValue>,
    isCustom: @escaping (SelectionValue) -> Bool,
    customTag: SelectionValue,
    customDefault: @escaping (SelectionValue) -> SelectionValue,
    customDescription: String? = nil,
    onCancelValue: SelectionValue? = nil,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder currentValueLabel: @escaping () -> CurrentValueLabel,
    @ViewBuilder customInput: @escaping (Binding<SelectionValue>) -> InputContent,
) -> some View where SelectionValue: Hashable & Equatable & Displayable, Content: View, InputContent: View, CurrentValueLabel: View {
    InputPicker(
        title: title,
        selection: selection,
        isCustom: isCustom,
        customTag: customTag,
        customDefault: customDefault,
        customDescription: customDescription,
        onCancelValue: onCancelValue,
        content: content,
        currentValueLabel: currentValueLabel,
        customInput: customInput
    )
}

func Picker<SelectionValue, Content, InputContent>(
    _ title: String,
    selection: Binding<SelectionValue>,
    isCustom: @escaping (SelectionValue) -> Bool,
    customTag: SelectionValue,
    customDefault: @escaping (SelectionValue) -> SelectionValue,
    customDescription: String? = nil,
    onCancelValue: SelectionValue? = nil,
    @ViewBuilder content: @escaping () -> Content,
    @ViewBuilder customInput: @escaping (Binding<SelectionValue>) -> InputContent
) -> some View where SelectionValue: Hashable & Equatable & Displayable, Content: View, InputContent: View {
    InputPicker<SelectionValue, Content, InputContent, EmptyView>(
        title: title,
        selection: selection,
        isCustom: isCustom,
        customTag: customTag,
        customDefault: customDefault,
        customDescription: customDescription,
        onCancelValue: onCancelValue,
        content: content,
        currentValueLabel: { EmptyView() },
        customInput: customInput,
    )
}

// MARK: - InputPicker

private struct InputPicker<SelectionValue, Content, InputContent, CurrentValueLabel>: View
    where SelectionValue: Hashable & Equatable & Displayable, Content: View, InputContent: View, CurrentValueLabel: View
{
    @Binding
    var selection: SelectionValue

    @State
    private var customValue: SelectionValue
    @State
    private var previousValue: SelectionValue
    @State
    private var isPresentingCustomInput = false

    let title: String
    let isCustom: (SelectionValue) -> Bool
    let customTag: SelectionValue
    let customDefault: (SelectionValue) -> SelectionValue
    let customDescription: String?
    let onCancelValue: SelectionValue?
    let content: () -> Content
    let currentValueLabel: () -> CurrentValueLabel
    let customInput: (Binding<SelectionValue>) -> InputContent

    init(
        title: String,
        selection: Binding<SelectionValue>,
        isCustom: @escaping (SelectionValue) -> Bool,
        customTag: SelectionValue,
        customDefault: @escaping (SelectionValue) -> SelectionValue,
        customDescription: String? = nil,
        onCancelValue: SelectionValue? = nil,
        @ViewBuilder content: @escaping () -> Content,
        @ViewBuilder currentValueLabel: @escaping () -> CurrentValueLabel,
        @ViewBuilder customInput: @escaping (Binding<SelectionValue>) -> InputContent
    ) {
        self.title = title
        self._selection = selection
        self._customValue = State(initialValue: customTag)
        self._previousValue = State(initialValue: selection.wrappedValue)
        self.isCustom = isCustom
        self.customTag = customTag
        self.customDefault = customDefault
        self.customDescription = customDescription
        self.onCancelValue = onCancelValue
        self.content = content
        self.currentValueLabel = currentValueLabel
        self.customInput = customInput
    }

    private var mappedSelection: Binding<SelectionValue> {
        Binding(
            get: { isCustom(selection) ? customTag : selection },
            set: { selection = $0 }
        )
    }

    @ViewBuilder
    private var pickerContent: some View {
        content()

        Divider()

        Text(L10n.custom)
            .tag(customTag)
    }

    @ViewBuilder
    private var picker: some View {
        if #available(iOS 18.0, tvOS 18.0, *), CurrentValueLabel.self != EmptyView.self {
            SwiftUI.Picker(title, selection: mappedSelection) {
                pickerContent
            } currentValueLabel: {
                currentValueLabel()
            }
        } else {
            SwiftUI.Picker(title, selection: mappedSelection) {
                pickerContent
            }
        }
    }

    var body: some View {
        picker
            .backport
            .onChange(of: selection) { oldValue, newValue in
                if newValue == customTag {
                    previousValue = oldValue
                    customValue = customDefault(oldValue)
                    isPresentingCustomInput = true
                }
            }
            .alert(L10n.custom, isPresented: $isPresentingCustomInput) {
                customInput($customValue)

                Button(L10n.save) {
                    selection = customValue
                }

                Button(L10n.cancel, role: .cancel) {
                    selection = onCancelValue ?? previousValue
                }
            } message: {
                if let customDescription {
                    Text(customDescription)
                }
            }
    }
}

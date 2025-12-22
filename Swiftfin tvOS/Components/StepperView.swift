//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct StepperView<Value: CustomStringConvertible & Strideable & LosslessStringConvertible, Formatter: FormatStyle>: View
    where Formatter.FormatInput == Value,
    Formatter.FormatOutput == String
{

    @Router
    private var router

    @Default(.accentColor)
    private var accentColor

    @FocusState
    private var isTextFieldFocused: Bool

    @Binding
    private var value: Value

    @State
    private var updatedValue: Value

    @State
    private var inputText: String

    private var range: ClosedRange<Value>
    private let step: Value.Stride
    private let formatter: Formatter

    // MARK: - Initializer

    init(
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride = 1,
        formatter: Formatter
    ) {
        self._value = value
        self._updatedValue = State(initialValue: value.wrappedValue)
        self._inputText = State(initialValue: value.wrappedValue.description)

        self.range = range
        self.step = step
        self.formatter = formatter
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .center, spacing: 30) {
            HStack {
                TextField(L10n.interval, text: $inputText)
                    .frame(width: 200)
                    .textFieldStyle(.plain)
                    .background(Color.clear)
                    .font(.title)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .keyboardType(.numberPad)
                    .focused($isTextFieldFocused)
                    .onChange(of: isTextFieldFocused) { _, focused in
                        if !focused {
                            commitInput()
                        }
                    }
                    .onSubmit {
                        commitInput()
                    }
            }

            HStack {
                Button {
                    if updatedValue > range.lowerBound {
                        updatedValue = max(updatedValue.advanced(by: -step), range.lowerBound)
                        inputText = String(describing: updatedValue)
                    }
                } label: {
                    Image(systemName: "minus")
                        .frame(width: 200, height: 75)
                        .font(.title2.weight(.bold))
                }

                Button {
                    if updatedValue < range.upperBound {
                        updatedValue = min(updatedValue.advanced(by: step), range.upperBound)
                        inputText = String(describing: updatedValue)
                    }
                } label: {
                    Image(systemName: "plus")
                        .frame(width: 200, height: 75)
                        .font(.title2.weight(.bold))
                }
            }

            Button(L10n.save) {
                value = updatedValue
                router.dismiss()
            }
            .buttonStyle(.primary)
            .frame(width: 200, height: 75)
            .foregroundStyle(accentColor.overlayColor, accentColor)
            .disabled(value == updatedValue)
        }
    }

    // MARK: - Commit Input

    private func commitInput() {
        if let parsed = Value(inputText) {
            updatedValue = min(max(parsed, range.lowerBound), range.upperBound)
        }
        inputText = String(describing: updatedValue)
    }
}

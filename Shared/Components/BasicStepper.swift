//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BasicStepper<Value: CustomStringConvertible & Strideable, Formatter: FormatStyle>: View
    where Formatter.FormatInput == Value, Formatter.FormatOutput == String
{

    @Binding
    private var value: Value

    private let title: String
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private let formatter: Formatter

    #if os(tvOS)
    @FocusState
    private var isFocused: Bool

    private var canDecrement: Bool {
        value.advanced(by: -step) >= range.lowerBound
    }

    private var canIncrement: Bool {
        value.advanced(by: step) <= range.upperBound
    }

    private func selectAction() {
        if canIncrement {
            value = value.advanced(by: step)
        } else {
            value = range.lowerBound
        }
    }
    #endif

    // MARK: - Body

    var body: some View {
        #if os(iOS)
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)

                Spacer()

                Text(value, format: formatter)
                    .foregroundColor(.secondary)
            }
        }
        #else
        Button {
            selectAction()
        } label: {
            HStack {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer()

                Image(systemName: "minus")
                    .font(.body.weight(.regular))
                    .foregroundStyle(canDecrement && isFocused ? .primary : .secondary)

                Text(value, format: formatter)
                    .foregroundStyle(.secondary)
                    .contentTransition(.numericText())
                    .animation(.default, value: value)

                Image(systemName: "plus")
                    .font(.body.weight(.regular))
                    .foregroundStyle(canIncrement && isFocused ? .primary : .secondary)
            }
        }
        .focused($isFocused)
        .buttonStyle(.plain)
        .onMoveCommand { direction in
            switch direction {
            case .left:
                if canDecrement {
                    value = value.advanced(by: -step)
                }
            case .right:
                if canIncrement {
                    value = value.advanced(by: step)
                }
            default:
                break
            }
        }
        #endif
    }
}

// MARK: - Initializers

extension BasicStepper {

    init(
        _ title: String,
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride = 1,
        formatter: Formatter
    ) {
        self._value = value
        self.title = title
        self.range = range
        self.step = step
        self.formatter = formatter
    }
}

extension BasicStepper where Formatter == VerbatimFormatStyle<Value> {

    init(
        _ title: String,
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride = 1
    ) {
        self._value = value
        self.title = title
        self.range = range
        self.step = step
        self.formatter = VerbatimFormatStyle()
    }
}

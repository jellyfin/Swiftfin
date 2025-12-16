//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BasicStepper<Value: CustomStringConvertible & Strideable, Formatter: FormatStyle>: View where Formatter.FormatInput == Value,
    Formatter.FormatOutput == String
{

    @Binding
    private var value: Value

    private let title: String
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private let formatter: Formatter

    #if os(tvOS)
    private var canDecrement: Bool {
        value.advanced(by: -step) >= range.lowerBound
    }

    private var canIncrement: Bool {
        value.advanced(by: step) <= range.upperBound
    }
    #endif

    // MARK: - Body

    var body: some View {
        #if os(tvOS)
        Button {
            if canIncrement {
                value = value.advanced(by: step)
            } else {
                value = range.lowerBound
            }
        } label: {
            HStack {
                Text(title)

                Spacer()

                Image(systemName: "minus")
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundStyle(canDecrement ? .secondary : .tertiary)

                Text(value, format: formatter)
                    .foregroundStyle(.secondary)

                Image(systemName: "plus")
                    .font(.body)
                    .fontWeight(.regular)
                    .foregroundStyle(canIncrement ? .secondary : .tertiary)
            }
        }
        .buttonStyle(StepperButtonStyle())
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
        #else
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)

                Spacer()

                Text(value, format: formatter)
                    .foregroundColor(.secondary)
            }
        }
        #endif
    }
}

// MARK: - tvOS Button Style

#if os(tvOS)
private struct StepperButtonStyle: PrimitiveButtonStyle {

    @FocusState
    private var isFocused: Bool

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(HierarchicalShapeStyle.secondary)
                    .brightness(isFocused ? 0.15 : 0.0)

                configuration.label
                    .foregroundStyle(.primary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
            }
        }
        .buttonStyle(.card)
        .focused($isFocused)
    }
}
#endif

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

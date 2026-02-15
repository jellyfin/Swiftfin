//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct Stepper<
    Value: CustomStringConvertible & Strideable,
    Formatter: FormatStyle,
    _Label: View,
    _Content: View
>: View
    where Formatter.FormatInput == Value,
    Formatter.FormatOutput == String
{

    @State
    private var isPresented: Bool = false

    @Binding
    private var value: Value

    private let formatter: Formatter
    private let label: () -> LabeledContent<_Label, _Content>
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private let title: String

    // MARK: - Initializer

    init(
        _ title: String,
        value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride = 1,
        formatter: Formatter,
        @ViewBuilder label: @escaping () -> LabeledContent<_Label, _Content>
    ) {
        self._value = value
        self.formatter = formatter
        self.label = label
        self.range = range
        self.step = step
        self.title = title
    }

    // MARK: - Body

    var body: some View {
        ChevronButton {
            isPresented = true
        } label: {
            label()
        }
        .inputSheet(title, isPresented: $isPresented) {
            Text(value, format: formatter)
                .font(.title3)
                .fontWeight(.semibold)
        } buttons: {
            HStack(spacing: 12) {
                Button {
                    if value > range.lowerBound {
                        value = max(value.advanced(by: -step), range.lowerBound)
                    }
                } label: {
                    Image(systemName: "minus")
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                }

                Button {
                    if value < range.upperBound {
                        value = min(value.advanced(by: step), range.upperBound)
                    }
                } label: {
                    Image(systemName: "plus")
                        .font(.body.weight(.bold))
                        .frame(maxWidth: .infinity)
                }
            }
        }
    }
}

// MARK: - VerbatimFormatStyle Convenience

extension Stepper where Formatter == VerbatimFormatStyle<Value> {

    init(
        _ title: String,
        value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride = 1,
        @ViewBuilder label: @escaping () -> LabeledContent<_Label, _Content>
    ) {
        self.init(
            title,
            value: value,
            in: range,
            step: step,
            formatter: VerbatimFormatStyle(),
            label: label
        )
    }
}

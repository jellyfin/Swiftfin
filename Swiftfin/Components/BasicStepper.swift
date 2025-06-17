//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BasicStepper<Value: CustomStringConvertible & Strideable, Formatter: FormatStyle>: View where Formatter.FormatInput == Value,
Formatter.FormatOutput == String {

    @Binding
    private var value: Value

    private let title: String
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private let formatter: Formatter

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)

                Spacer()

                Text(value, format: formatter)
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension BasicStepper {

    init(
        _ title: String,
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride = 1,
        formatter: Formatter
    ) {
        self.init(
            value: value,
            title: title,
            range: range,
            step: step,
            formatter: formatter
        )
    }
}

extension BasicStepper where Formatter == VerbatimFormatStyle<Value> {
    init(
        _ title: String,
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride = 1
    ) {
        self.init(
            value: value,
            title: title,
            range: range,
            step: step,
            formatter: VerbatimFormatStyle()
        )
    }
}

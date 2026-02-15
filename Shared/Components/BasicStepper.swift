//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@available(iOS, deprecated, message: "Use a Stepper with a `LabeledContent` label directly instead")
struct BasicStepper<Value: CustomStringConvertible & Strideable & LosslessStringConvertible, Formatter: FormatStyle>: View
    where Formatter.FormatInput == Value,
    Formatter.FormatOutput == String
{

    #if os(tvOS)
    @Router
    private var router
    #endif

    private let title: String
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private let formatter: Formatter
    private let value: Binding<Value>

    init(
        _ title: String,
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride = 1,
        formatter: Formatter
    ) {
        self.title = title
        self.range = range
        self.step = step
        self.formatter = formatter
        self.value = value
    }

    var body: some View {
        #if os(iOS)
        Stepper(value: value, in: range, step: step) {
            LabeledContent(title) {
                Text(value.wrappedValue, format: formatter)
            }
        }
        #else
        ChevronButton(title, subtitle: Text(value.wrappedValue, format: formatter)) {
            router.route(to: .stepperView(
                title: title,
                value: value,
                range: range,
                step: step,
                formatter: formatter
            ))
        }
        #endif
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
            title,
            value: value,
            range: range,
            step: step,
            formatter: VerbatimFormatStyle()
        )
    }
}

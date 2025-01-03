//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BasicStepper<Value: CustomStringConvertible & Strideable>: View {

    @Binding
    private var value: Value

    private let title: String
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private var formatter: (Value) -> String

    var body: some View {
        Stepper(value: $value, in: range, step: step) {
            HStack {
                Text(title)

                Spacer()

                formatter(value).text
                    .foregroundColor(.secondary)
            }
        }
    }
}

extension BasicStepper {

    init(
        title: String,
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride
    ) {
        self.init(
            value: value,
            title: title,
            range: range,
            step: step,
            formatter: { $0.description }
        )
    }

    func valueFormatter(_ formatter: @escaping (Value) -> String) -> Self {
        copy(modifying: \.formatter, with: formatter)
    }
}

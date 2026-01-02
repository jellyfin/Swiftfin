//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct StepperView<Value: CustomStringConvertible & Strideable>: View {

    @Binding
    private var value: Value

    @State
    private var updatedValue: Value
    @Environment(\.presentationMode)
    private var presentationMode

    private var title: String
    private var description: String?
    private var range: ClosedRange<Value>
    private let step: Value.Stride
    private var formatter: (Value) -> String
    private var onCloseSelected: () -> Void

    var body: some View {
        VStack {
            VStack {
                Spacer()

                Text(title)
                    .font(.title)
                    .fontWeight(.semibold)

                if let description {
                    Text(description)
                        .padding(.vertical)
                }
            }
            .frame(maxHeight: .infinity)

            Text(formatter(updatedValue))
                .font(.title)
                .frame(height: 250)

            VStack {

                HStack {
                    Button {
                        if updatedValue > range.lowerBound {
                            updatedValue = max(updatedValue.advanced(by: -step), range.lowerBound)
                            value = updatedValue
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.title2.weight(.bold))
                            .frame(width: 200, height: 75)
                    }
                    .buttonStyle(.card)

                    Button {
                        if updatedValue < range.upperBound {
                            updatedValue = min(updatedValue.advanced(by: step), range.upperBound)
                            value = updatedValue
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .frame(width: 200, height: 75)
                    }
                    .buttonStyle(.card)
                }

                Button(L10n.close) {
                    onCloseSelected()
                    presentationMode.wrappedValue.dismiss()
                }

                Spacer()
            }
            .frame(maxHeight: .infinity)
        }
    }
}

extension StepperView {

    init(
        title: String,
        description: String? = nil,
        value: Binding<Value>,
        range: ClosedRange<Value>,
        step: Value.Stride
    ) {
        self._value = value
        self._updatedValue = State(initialValue: value.wrappedValue)
        self.title = title
        self.description = description
        self.range = range
        self.step = step
        self.formatter = { $0.description }
        self.onCloseSelected = {}
    }

    func valueFormatter(_ formatter: @escaping (Value) -> String) -> Self {
        copy(modifying: \.formatter, with: formatter)
    }

    func onCloseSelected(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onCloseSelected, with: action)
    }
}

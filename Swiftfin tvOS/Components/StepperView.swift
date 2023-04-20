//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct StepperView<Value: CustomStringConvertible & Strideable>: View {

    @Binding
    private var value: Value

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

            formatter(value).text
                .font(.title)
                .frame(height: 250)

            VStack {

                HStack {
                    Button {
                        guard value >= range.lowerBound else { return }
                        value = value.advanced(by: -step)
                    } label: {
                        Image(systemName: "minus")
                            .font(.title2.weight(.bold))
                            .frame(width: 200, height: 75)
                    }
                    .buttonStyle(.card)

                    Button {
                        guard value <= range.upperBound else { return }
                        value = value.advanced(by: step)
                    } label: {
                        Image(systemName: "plus")
                            .font(.title2.weight(.bold))
                            .frame(width: 200, height: 75)
                    }
                    .buttonStyle(.card)
                }

                Button {
                    onCloseSelected()
                } label: {
                    Text("Close")
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
        self.init(
            value: value,
            title: title,
            description: description,
            range: range,
            step: step,
            formatter: { $0.description },
            onCloseSelected: {}
        )
    }

    func valueFormatter(_ formatter: @escaping (Value) -> String) -> Self {
        copy(modifying: \.formatter, with: formatter)
    }

    func onCloseSelected(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onCloseSelected, with: action)
    }
}

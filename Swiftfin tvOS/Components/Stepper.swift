//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: respond to swipes

struct Stepper<
    Value: CustomStringConvertible & Strideable,
    Format: FormatStyle<Value, String>,
    Label: View,
    Content: View
>: View {

    @Binding
    private var value: Value

    @State
    private var isPresented = false

    private let format: Format
    private let label: LabeledContent<Label, Content>
    private let range: ClosedRange<Value>
    private let step: Value.Stride
    private let title: String

    private var canDecrement: Bool {
        value > range.lowerBound
    }

    private var canIncrement: Bool {
        value < range.upperBound
    }

    init(
        _ title: String,
        value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride = 1,
        format: Format,
        @ViewBuilder label: @escaping () -> LabeledContent<Label, Content>
    ) {
        self._value = value
        self.format = format
        self.label = label()
        self.range = range
        self.step = step
        self.title = title
    }

    // MARK: - Body

    var body: some View {
        ChevronButton {
            isPresented = true
        } label: {
            label
        }
        ._alert(title, isPresented: $isPresented) {
            VStack {
                HStack(spacing: 24) {
                    Button("Decrement", systemImage: "minus") {
                        value = min(range.upperBound, value.advanced(by: -step))
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canDecrement)

                    Text(value, format: format)
                        .font(.headline)
                        .fontDesign(.rounded)
                        .monospacedDigit()
                        .foregroundStyle(.white)
                        .frame(height: 80)
                        .frame(minWidth: 100)
                        .padding(.horizontal, 24)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.white.opacity(0.08))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .strokeBorder(.white.opacity(0.18), lineWidth: 1)
                        )

                    Button("Increment", systemImage: "plus") {
                        value = min(range.upperBound, value.advanced(by: step))
                    }
                    .buttonStyle(.bordered)
                    .disabled(!canIncrement)
                }
                .labelStyle(.iconOnly)
                .focusSection()

                Button {
                    isPresented = false
                } label: {
                    AlternateLayoutView {
                        Color.clear
                            .aspectRatio(3.5, contentMode: .fit)
                            .frame(height: 40)
                    } content: {
                        Text(L10n.close)
                    }
                }
            }
            .onAppear {
                value = min(max(value, range.lowerBound), range.upperBound)
            }
        }
    }
}

extension Stepper where Format == VerbatimFormatStyle<Value> {

    init(
        _ title: String,
        value: Binding<Value>,
        in range: ClosedRange<Value>,
        step: Value.Stride = 1,
        @ViewBuilder label: @escaping () -> LabeledContent<Label, Content>
    ) {
        self.init(
            title,
            value: value,
            in: range,
            step: step,
            format: VerbatimFormatStyle(),
            label: label
        )
    }
}

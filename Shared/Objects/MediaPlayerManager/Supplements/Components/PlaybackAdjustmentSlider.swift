//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PlaybackAdjustmentSlider: View {

    @Binding
    var value: Double

    let title: String
    let range: ClosedRange<Double>
    let step: Double
    let presets: [Double]
    let resetValue: Double
    let formatValue: (Double) -> String
    var focusID: String?

    private var sliderValue: Binding<Double> {
        Binding(
            get: { clamp(value, min: range.lowerBound, max: range.upperBound) },
            set: { value = clamp(round($0, toNearest: step), min: range.lowerBound, max: range.upperBound) }
        )
    }

    @ViewBuilder
    private var slider: some View {
        #if os(tvOS)
        SliderContainer(
            value: Binding(
                get: { sliderValue.wrappedValue - range.lowerBound },
                set: { sliderValue.wrappedValue = $0 + range.lowerBound }
            ),
            total: range.upperBound - range.lowerBound
        )
        .sliderContainerStyle(.capsule(neutralProgress: (resetValue - range.lowerBound) / (range.upperBound - range.lowerBound)))
        .frame(height: 16)
        .ifLet(focusID) { view, id in
            view.coordinatedFocus(id)
        }
        #else
        Group {
            if #available(iOS 26, *) {
                // The binding snaps to steps without the native slider's automatic tick marks.
                Slider(value: sliderValue, in: range, neutralValue: resetValue) {
                    EmptyView()
                }
            } else {
                Slider(value: sliderValue, in: range, step: step)
            }
        }
        .tint(.white)
        #endif
    }

    @ViewBuilder
    private var presetButtons: some View {
        ForEach(presets, id: \.self) { preset in
            Button(preset == resetValue ? L10n.reset : formatValue(preset)) {
                sliderValue.wrappedValue = preset
            }
            .monospacedDigit()
            .fixedSize()
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(formatValue(value))
                .font(.headline)
                .monospacedDigit()
                .contentTransition(.numericText(value: value))
                .animation(.easeInOut(duration: 0.15), value: value)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .backport
                .glassEffect(.regular.interactive(false), in: .capsule)

            HStack(spacing: 12) {
                Button { sliderValue.wrappedValue = value - step } label: {
                    Label(L10n.decrease, systemImage: "minus")
                        .labelStyle(.iconOnly)
                        .frame(width: 24, height: 34)
                }
                .disabled(value <= range.lowerBound)

                VStack(spacing: 0) {
                    slider
                        .accessibilityLabel(title)
                        .accessibilityValue(formatValue(value))
                        .accessibilityAdjustableAction { direction in
                            switch direction {
                            case .increment: sliderValue.wrappedValue = value + step
                            case .decrement: sliderValue.wrappedValue = value - step
                            @unknown default: break
                            }
                        }

                    HStack {
                        Text(formatValue(range.lowerBound))
                        Spacer(minLength: 8)
                        Text(formatValue(range.upperBound))
                    }
                    .font(.caption2)
                    .monospacedDigit()
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
                    .accessibilityHidden(true)
                }

                Button { sliderValue.wrappedValue = value + step } label: {
                    Label(L10n.increase, systemImage: "plus")
                        .labelStyle(.iconOnly)
                        .frame(width: 24, height: 34)
                }
                .disabled(value >= range.upperBound)
            }
            .buttonStyle(.capsule)

            FlowLayout(alignment: .center, direction: .down, spacing: 8, lineSpacing: 8) {
                presetButtons
            }
            .frame(maxWidth: .infinity)
            #if os(tvOS)
            .focusSection()
            #endif
            .buttonStyle(.capsule)
            .padding(.top, 4)
        }
        .accessibilityElement(children: .contain)
    }
}

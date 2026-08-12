//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ColorPicker {

    struct Sheet: View {

        @Environment(\.dismiss)
        private var dismiss

        let title: String
        let value: Binding<Color>
        let supportsOpacity: Bool

        @ViewBuilder
        private func gradientSection(for component: WritableKeyPath<Color.RGBA, CGFloat>, title: String) -> some View {
            Section {
                ColorGradientSlider(
                    color: value,
                    component: component
                )
                .frame(height: 36)
            } header: {
                HStack {
                    Text(title)
                        .textCase(.uppercase)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    Text(Int(value.wrappedValue.rgbaComponents[keyPath: component] * 255), format: .number)
                        .monospacedDigit()
                }
            }
        }

        var body: some View {
            VStack(spacing: 8) {
                HStack(spacing: 24) {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(value.wrappedValue)
                        .aspectRatio(1, contentMode: .fit)

                    StateAdapter(initialValue: value.wrappedValue.hexString) { hexString in
                        TextField(L10n.hexColor, text: hexString)
                            .onSubmit {
                                value.wrappedValue = Color(hex: String(hexString.wrappedValue.prefix(6)))
                            }
                            .monospaced()
                    }
                    .id(value.wrappedValue)

                    Menu {
                        ForEach(ColorPickerDefaults.allCases, id: \.hashValue) { color in
                            Button {
                                value.wrappedValue = color.color
                            } label: {
                                Text(color.displayTitle)
                                Image(systemName: "circle.fill")
                            }
                            .foregroundStyle(color.color, .primary, .secondary)
                        }
                    } label: {
                        Image(systemName: "paintpalette.fill")
                            .frame(width: 30, height: 30)
                    }
                }
                .frame(height: 75)
                .focusSection()

                gradientSection(for: \.red, title: L10n.red)

                gradientSection(for: \.green, title: L10n.green)

                gradientSection(for: \.blue, title: L10n.blue)

                if supportsOpacity {
                    gradientSection(for: \.alpha, title: L10n.opacity)
                }

                Spacer(minLength: 0)

                Button {
                    dismiss()
                } label: {
                    Text(L10n.close)
                        .frame(maxWidth: .infinity)
                }
                .fontWeight(.semibold)
                .backport
                .buttonStyle(.glassProminent.shadow(false))
                .frame(maxHeight: 44)
                .focusSection()
            }
            .navigationTitle(title)
            .edgePadding([.bottom, .horizontal])
        }
    }
}

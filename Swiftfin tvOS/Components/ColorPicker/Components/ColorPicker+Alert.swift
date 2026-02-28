//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Engine
import SwiftUI

// TODO: opacity

extension ColorPicker {

    struct _Alert: View {

        @Environment(\.dismiss)
        private var dismiss

        let value: Binding<Color>

        private func gradientSection(for component: WritableKeyPath<Color.RGBA, CGFloat>, title: String) -> some View {
            Section {
                ColorGradientSlider(
                    color: value,
                    component: component
                )
                .frame(height: 70)
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
            EqualWidthVStack {
                HStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(value.wrappedValue)
                        .aspectRatio(1, contentMode: .fit)
                        .frame(width: 200)

                    VStack {

                        gradientSection(for: \.red, title: L10n.red)

                        gradientSection(for: \.green, title: L10n.green)

                        gradientSection(for: \.blue, title: L10n.blue)

                        HStack {
                            Text(L10n.hexColor)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            StateAdapter(initialValue: value.wrappedValue.hexString) { hexString in
                                TextField(L10n.hexColor, text: hexString)
                                    .onSubmit {
                                        value.wrappedValue = Color(hex: String(hexString.wrappedValue.prefix(6)))
                                    }
                                    .monospaced()
                            }
                            .id(value.wrappedValue)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 10)
                        .focusSection()

                        HStack {
                            Text(L10n.color)
                                .frame(maxWidth: .infinity, alignment: .leading)

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
                        .padding(.top, 10)
                        .focusSection()
                    }
                    .frame(width: 600)
                }

                Button {
                    dismiss()
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
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct AccentColorSettingsView: View {
    @Default(.accentColor)
    private var accentColor

    @State
    private var red: CGFloat
    @State
    private var green: CGFloat
    @State
    private var blue: CGFloat

    @FocusState
    private var isRedFocused: Bool
    @FocusState
    private var isGreenFocused: Bool
    @FocusState
    private var isBlueFocused: Bool

    private var sliderHeight: CGFloat = 48
    private var maximumWidth: CGFloat = 1000
    private var sliderIndicatorWidth: CGFloat = 8

    @State
    private var hexString: String

    struct NamedColor: Hashable {
        let name: String
        let value: Color

        static let availableColors: [NamedColor] = [
            NamedColor(name: L10n.jellyfin, value: .jellyfinPurple),
            NamedColor(name: L10n.red, value: .red),
            NamedColor(name: L10n.orange, value: .orange),
            NamedColor(name: L10n.yellow, value: .yellow),
            NamedColor(name: L10n.green, value: .green),
            NamedColor(name: L10n.blue, value: .blue),
        ]
    }

    enum ColorComponent {
        case red
        case green
        case blue
    }

    private func handleMoveCommand(colorComponent: ColorComponent, _ direction: MoveCommandDirection) {
        if direction != .left && direction != .right { return }
        var step = 1 / 255.0
        if direction == .left {
            step = -step
        }

        switch colorComponent {
        case .red:
            setColorComponent(red: red + step, green: nil, blue: nil)
        case .green:
            setColorComponent(red: nil, green: green + step, blue: nil)
        case .blue:
            setColorComponent(red: nil, green: nil, blue: blue + step)
        }
    }

    var body: some View {
        VStack(alignment: .center) {

            Text(L10n.accentColor)
                .font(.title)

            colorSlider(label: L10n.red, value: $red, focusState: $isRedFocused, colorComponent: .red)
            colorSlider(label: L10n.green, value: $green, focusState: $isGreenFocused, colorComponent: .green)
            colorSlider(label: L10n.blue, value: $blue, focusState: $isBlueFocused, colorComponent: .blue)

            ListRowButton(hexString) {}
                .font(.title)
                .foregroundStyle(accentColor.overlayColor, accentColor)

            Menu {
                ForEach(NamedColor.availableColors, id: \.self) { color in
                    Button(action: {
                        guard accentColor != color.value else { return }
                        setColor(color: color.value)
                    }) {
                        Text(color.name)
                            .foregroundColor(.primary)
                    }
                }
            } label: {
                HStack {
                    Text(L10n.color)
                    Spacer()
                    if NamedColor.availableColors.filter({ $0.value.equals(accentColor) }).isNotEmpty {
                        Circle()
                            .fill(accentColor)
                            .frame(width: 16, height: 16)
                    }
                }
            }
            .listRowBackground(Color.clear)
            .listRowInsets(.zero)
            .foregroundStyle(.primary, .secondary)
        }.frame(maxWidth: maximumWidth)
    }

    init() {
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0
        Default(.accentColor).wrappedValue.uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)

        self.hexString = String(format: "#%02X%02X%02X", Int(255 * red), Int(255 * green), Int(255 * blue))
        self.red = red
        self.green = green
        self.blue = blue
    }

    private func colorSlider(
        label: String,
        value: Binding<CGFloat>,
        focusState: FocusState<Bool>.Binding,
        colorComponent: ColorComponent
    ) -> some View {
        VStack {
            HStack {
                Text(label)
                Spacer()
                Text(Int(255 * value.wrappedValue).description)
            }
            .font(.system(size: 20, weight: .medium))
            .foregroundColor(focusState.wrappedValue ? .primary : .secondary)

            Button {
                GeometryReader { _ in
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(
                                    red: colorComponent == .red ? 0 : red,
                                    green: colorComponent == .green ? 0 : green,
                                    blue: colorComponent == .blue ? blue : 0
                                ),
                                Color(red: red, green: green, blue: blue),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: maximumWidth * value.wrappedValue)

                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: red, green: green, blue: blue),
                                Color(
                                    red: colorComponent == .red ? 1 : red,
                                    green: colorComponent == .green ? 1 : green,
                                    blue: colorComponent == .blue ? blue : 1
                                ),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.6)
                        .padding(.leading, maximumWidth * value.wrappedValue)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(.primary)
                            .frame(width: sliderIndicatorWidth)
                            .padding(.leading, maximumWidth * value.wrappedValue - sliderIndicatorWidth / 2)
                    }
                }
            }
            .buttonStyle(.card)
            .frame(height: sliderHeight)
            .onMoveCommand(perform: { (direction: MoveCommandDirection) in
                handleMoveCommand(colorComponent: colorComponent, direction)
            })
            .opacity(focusState.wrappedValue ? 1 : 0.8)
        }
    }

    private func setColor(color: Color) {
        color.uiColor.getRed(&red, green: &green, blue: &blue, alpha: nil)
        accentColor = color
        hexString = String(format: "#%02X%02X%02X", Int(255 * red), Int(255 * green), Int(255 * blue))
    }

    private func setColorComponent(red: CGFloat?, green: CGFloat?, blue: CGFloat?) {
        if red != nil {
            self.red = min(1, max(0, red.unsafelyUnwrapped))
        }

        if green != nil {
            self.green = min(1, max(0, green.unsafelyUnwrapped))
        }

        if blue != nil {
            self.blue = min(1, max(0, blue.unsafelyUnwrapped))
        }
        accentColor = Color(.sRGB, red: self.red, green: self.green, blue: self.blue)
        hexString = String(format: "#%02X%02X%02X", Int(255 * self.red), Int(255 * self.green), Int(255 * self.blue))
    }
}

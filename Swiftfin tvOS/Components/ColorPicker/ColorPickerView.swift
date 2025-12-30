//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ColorPickerView: View {

    enum ColorComponent {
        case red
        case green
        case blue
        case opacity
    }

    // MARK: Parameters

    @Binding
    private var color: Color

    private let supportsOpacity: Bool

    // MARK: Color Components

    @State
    private var red: CGFloat
    @State
    private var green: CGFloat
    @State
    private var blue: CGFloat
    @State
    private var opacity: CGFloat

    // MARK: Color Hex Value

    @State
    private var hexString: String
    @State
    private var tempHexString: String = ""

    // MARK: Error State

    @State
    private var error: Error?

    // MARK: - Initializer

    init(color: Binding<Color>, supportsOpacity: Bool = false) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.wrappedValue.uiColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let hexString = String(format: "#%02X%02X%02X", Int(255 * r), Int(255 * g), Int(255 * b))

        self.supportsOpacity = supportsOpacity

        self.red = r
        self.green = g
        self.blue = b
        self.opacity = supportsOpacity ? a : 1
        self.hexString = hexString
        self.tempHexString = hexString
        self._color = color
    }

    // MARK: - Body

    var body: some View {
        SplitFormWindowView()
            .descriptionView {
                descriptionView
            }
            .contentView {
                slidersView
                manualInputsView
            }
            .errorMessage($error)
    }

    private var descriptionView: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .fill(color)
                    .overlay(
                        Circle()
                            .stroke(
                                Color.white.opacity(1.0 - opacity),
                                lineWidth: 1.5
                            )
                    )
                Text(hexString)
                    .font(.headline)
                    .fontWeight(.bold)
                    .fontDesign(.monospaced)
                    .foregroundStyle(color.overlayColor)
            }

            FlowLayout(
                alignment: .center,
                direction: .down,
                spacing: 20,
                lineSpacing: 10,
                minRowLength: 2
            ) {
                let colors: [Color] = supportsOpacity ? [.red, .green, .blue, .gray] : [.red, .green, .blue]

                ForEach(colors, id: \.self) { color in
                    let value: CGFloat = switch color {
                    case .red: red
                    case .green: green
                    case .blue: blue
                    case .gray: opacity
                    default: 0
                    }

                    Label {
                        Text(String(format: "%-3d", Int(value * 255)))
                            .monospaced()
                    } icon: {
                        Circle()
                            .frame(width: 32, height: 32)
                    }
                    .foregroundStyle(color)
                }
            }
            .font(.body)
        }
        .frame(width: 400, height: 400)
    }

    @ViewBuilder
    private var slidersView: some View {
        colorSlider(label: L10n.red, value: $red, colorComponent: .red)
        colorSlider(label: L10n.green, value: $green, colorComponent: .green)
        colorSlider(label: L10n.blue, value: $blue, colorComponent: .blue)

        if supportsOpacity {
            colorSlider(label: L10n.opacity, value: $opacity, colorComponent: .opacity)
        }
    }

    @ViewBuilder
    private var manualInputsView: some View {
        Section(L10n.otherInputs) {
            TextField(L10n.hexInput, text: $tempHexString) {
                if let newColor = Color(hex: tempHexString) {
                    if newColor != color {
                        update(color: newColor)
                    }
                } else {
                    error = JellyfinAPIError(L10n.unknownError)
                }
            }
            .listRowInsets(.zero)
            .frame(height: 70)

            ListRowMenu(L10n.color, subtitle: {
                Circle()
                    .fill(color)
                    .frame(width: 30, height: 30)
            }) {
                Picker(L10n.color, selection: Binding<ColorPickerDefaults?>(
                    get: { ColorPickerDefaults.allCases.first(where: { $0.color.isEqual(to: color) }) },
                    set: { if let newValue = $0 { update(color: newValue.color) } }
                )) {
                    ForEach(ColorPickerDefaults.allCases, id: \.self) { colorItem in
                        Text(colorItem.displayTitle).tag(colorItem as ColorPickerDefaults?)
                    }
                }
            }
            .frame(height: 70)
        }
    }

    // MARK: - Color Slider

    @ViewBuilder
    private func colorSlider(
        label: String,
        value: Binding<CGFloat>,
        colorComponent: ColorComponent
    ) -> some View {
        Section {
            Button {} label: {
                GeometryReader { geo in
                    let startColor: Color = colorComponent == .opacity
                        ? Color(red: red, green: green, blue: blue, opacity: 0)
                        : Color(
                            red: colorComponent == .red ? 0 : red,
                            green: colorComponent == .green ? 0 : green,
                            blue: colorComponent == .blue ? 0 : blue
                        )

                    let endColor: Color = colorComponent == .opacity
                        ? Color(red: red, green: green, blue: blue, opacity: 1)
                        : Color(
                            red: colorComponent == .red ? 1 : red,
                            green: colorComponent == .green ? 1 : green,
                            blue: colorComponent == .blue ? 1 : blue
                        )

                    let width = geo.size.width - 24
                    let cursorPosition = 8 + width * value.wrappedValue

                    ZStack(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(colors: [startColor, endColor]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        RoundedRectangle(cornerRadius: 8)
                            .fill(.primary)
                            .frame(width: 8)
                            .offset(x: cursorPosition)
                    }
                }
            }
            .onMoveCommand { direction in
                handleMoveCommand(colorComponent: colorComponent, direction)
            }
            .buttonStyle(.card)
        } header: {
            HStack {
                Text(label)
                Spacer()
                Text(Int(255 * value.wrappedValue).description)
            }
            .padding()
        }
        .frame(height: 65)
        .listRowInsets(.zero)
    }

    // MARK: - Handle Cursor Movement

    private func handleMoveCommand(colorComponent: ColorComponent, _ direction: MoveCommandDirection) {
        if direction != .left && direction != .right { return }
        var step = 1 / 255.0
        if direction == .left {
            step = -step
        }

        switch colorComponent {
        case .red:
            self.red = min(1, max(0, self.red + step))
        case .green:
            self.green = min(1, max(0, self.green + step))
        case .blue:
            self.blue = min(1, max(0, self.blue + step))
        case .opacity:
            self.opacity = min(1, max(0, self.opacity + step))
        }

        self.color = Color(red: self.red, green: self.green, blue: self.blue, opacity: self.opacity)

        self.hexString = color.hexString(includeOpacity: supportsOpacity)
        self.tempHexString = self.hexString
    }

    // MARK: - Update Color Value

    private func update(color: Color) {
        var alpha: CGFloat = 0
        color.uiColor.getRed(&self.red, green: &self.green, blue: &self.blue, alpha: &alpha)
        
        if self.supportsOpacity {
            self.color = color
            self.opacity = alpha
        } else {
            self.color = Color(red: self.red, green: self.green, blue: self.blue)
        }

        self.hexString = color.hexString(includeOpacity: supportsOpacity)
        self.tempHexString = self.hexString
    }
}

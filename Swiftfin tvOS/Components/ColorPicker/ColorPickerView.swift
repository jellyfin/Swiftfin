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

    // MARK: Focus States

    @FocusState
    private var isRedFocused: Bool
    @FocusState
    private var isGreenFocused: Bool
    @FocusState
    private var isBlueFocused: Bool
    @FocusState
    private var isOpacityFocused: Bool
    @FocusState
    private var isMenuFocused: Bool

    // MARK: Error State

    @State
    private var error: Error?

    // MARK: Show Keyboard

    @State
    private var showHexInput: Bool = false

    // MARK: Sizing & spacing

    private static let sliderHeight: CGFloat = 48
    private static let sliderIndicatorWidth: CGFloat = 8
    private static let maximumWidth: CGFloat = 1000

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
        VStack(alignment: .center) {

            colorSlider(label: L10n.red, value: $red, focusState: $isRedFocused, colorComponent: .red)
            colorSlider(label: L10n.green, value: $green, focusState: $isGreenFocused, colorComponent: .green)
            colorSlider(label: L10n.blue, value: $blue, focusState: $isBlueFocused, colorComponent: .blue)

            if supportsOpacity {
                // TODO: Localize
                // We never really use opacity in Swiftfin but it's called as false frequently.
                // Do we want to mirror the API for ease of platform logic or just drop it?
                // Is there ever a case where we'd want opacity?
                colorSlider(
                    label: "Opacity",
                    value: $opacity,
                    focusState: $isOpacityFocused,
                    colorComponent: .opacity
                )
            }

            Divider()

            Form {
                ListRowButton(hexString) {
                    showHexInput = true
                }
                .font(.title)
                .listRowInsets(.zero)
                .foregroundStyle(color.overlayColor, color)
                // TODO: Rebase on Main and replace ListRowButton with Button & .buttonStyle(.primary)
                // https://github.com/jellyfin/Swiftfin/issues/1817

                ListRowMenu(L10n.color, subtitle: {
                    if let selected = ColorPickerDefaults.allCases.first(where: { $0.color.isEqual(to: color) }) {
                        Circle()
                            .fill(selected.color)
                            .frame(width: 30, height: 30)
                    }
                }) {
                    Picker(L10n.color, selection: Binding<ColorPickerDefaults?>(
                        get: { ColorPickerDefaults.allCases.first(where: { $0.color.isEqual(to: color) }) },
                        set: { if let newValue = $0 { updateFromColor(color: newValue.color) } }
                    )) {
                        ForEach(ColorPickerDefaults.allCases, id: \.self) { colorItem in
                            Text(colorItem.displayTitle).tag(colorItem as ColorPickerDefaults?)
                        }
                    }
                }
                .focused($isMenuFocused)
            }
            .scrollClipDisabled()
        }
        .frame(maxWidth: ColorPickerView.maximumWidth)
        .errorMessage($error)

        KeyboardTextField(
            text: $tempHexString,
            isFirstResponder: $showHexInput
        ) {
            updateFromHex()
        }
        .frame(width: 0, height: 0).opacity(0)
    }

    // MARK: - Color Slider

    @ViewBuilder
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

            Button {} label: {
                GeometryReader { _ in
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

                    ZStack(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(colors: [startColor, endColor]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )

                        RoundedRectangle(cornerRadius: ColorPickerView.sliderIndicatorWidth)
                            .fill(.primary)
                            .frame(width: ColorPickerView.sliderIndicatorWidth)
                            .padding(.leading, ColorPickerView.maximumWidth * value.wrappedValue - ColorPickerView.sliderIndicatorWidth / 2)
                    }
                }
            }
            .onMoveCommand { direction in
                handleMoveCommand(colorComponent: colorComponent, direction)
            }
            .buttonStyle(.card)
            .frame(height: ColorPickerView.sliderHeight)
            .opacity(focusState.wrappedValue ? 1 : 0.8)
        }
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

    // MARK: - Update Logic

    private func updateFromHex() {
        guard let newColor = Color(hex: tempHexString) else {
            error = JellyfinAPIError(L10n.invalidFormat)
            return
        }

        updateFromColor(color: newColor)
    }

    private func updateFromColor(color: Color) {
        self.color = color
        var alpha: CGFloat = 0
        color.uiColor.getRed(&self.red, green: &self.green, blue: &self.blue, alpha: &alpha)
        self.opacity = supportsOpacity ? alpha : 1

        self.hexString = color.hexString(includeOpacity: supportsOpacity)
        self.tempHexString = self.hexString
    }
}

private struct KeyboardTextField: UIViewRepresentable {
    @Binding
    var text: String
    @Binding
    var isFirstResponder: Bool
    var onCommit: (() -> Void)?

    func makeUIView(context: Context) -> UITextField {
        let textField = UITextField(frame: .zero)
        textField.isHidden = true
        textField.delegate = context.coordinator
        textField.autocorrectionType = .no
        textField.autocapitalizationType = .allCharacters
        textField.keyboardType = .asciiCapable
        return textField
    }

    func updateUIView(_ uiView: UITextField, context: Context) {
        uiView.text = text

        if isFirstResponder, uiView.window != nil {
            DispatchQueue.main.async {
                uiView.becomeFirstResponder()
            }
        } else if !isFirstResponder, uiView.isFirstResponder {
            uiView.resignFirstResponder()
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    class Coordinator: NSObject, UITextFieldDelegate {
        var parent: KeyboardTextField
        init(_ parent: KeyboardTextField) { self.parent = parent }

        func textFieldDidChangeSelection(_ textField: UITextField) {
            parent.text = textField.text ?? ""
        }

        func textFieldDidEndEditing(_ textField: UITextField) {
            parent.isFirstResponder = false
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            textField.resignFirstResponder()
            parent.isFirstResponder = false
            parent.onCommit?()
            return true
        }
    }
}

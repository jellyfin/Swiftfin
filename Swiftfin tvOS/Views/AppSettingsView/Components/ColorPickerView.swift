//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct ColorPickerView: View {
    @Binding
    private var color: Color

    @State
    private var red: CGFloat
    @State
    private var green: CGFloat
    @State
    private var blue: CGFloat
    @State
    private var hexString: String
    @State
    private var tempHexString: String = ""
    @State
    private var showHexInput: Bool = false
    @State
    private var showHexError = false

    @FocusState
    private var isRedFocused: Bool
    @FocusState
    private var isGreenFocused: Bool
    @FocusState
    private var isBlueFocused: Bool
    @FocusState
    private var isMenuFocused: Bool

    private static let sliderHeight: CGFloat = 48
    private static let sliderIndicatorWidth: CGFloat = 8
    private static let maximumWidth: CGFloat = 1000

    enum ColorComponent { case red, green, blue }

    var body: some View {
        VStack(alignment: .center) {
            colorSlider(label: L10n.red, value: $red, focusState: $isRedFocused, colorComponent: .red)
            colorSlider(label: L10n.green, value: $green, focusState: $isGreenFocused, colorComponent: .green)
            colorSlider(label: L10n.blue, value: $blue, focusState: $isBlueFocused, colorComponent: .blue)

            Divider()

            ListRowButton(hexString) {
                showHexInput = true
            }
            .font(.title)
            .foregroundStyle(color.overlayColor, color)

            Form {
                ListRowMenu(L10n.color, subtitle: {
                    if let selected = ColorPickerDefaults.allCases.first(where: { $0.color.isEqual(to: color) }) {
                        Circle()
                            .fill(selected.color)
                            .frame(width: 24, height: 24)
                            .brightness(isMenuFocused ? -0.4 : 0)
                    }
                }) {
                    ForEach(ColorPickerDefaults.allCases, id: \.self) { colorItem in
                        Button {
                            updateFromColor(color: colorItem.color)
                        } label: {
                            Text(colorItem.displayTitle)
                        }
                    }
                }
                .focused($isMenuFocused)
            }
            .padding(.top, -24)
            .scrollClipDisabled()
        }
        .frame(maxWidth: ColorPickerView.maximumWidth)
        .alert(isPresented: $showHexError) {
            Alert(
                title: Text(L10n.invalidFormat),
                message: Text("#RRGGBB"),
                dismissButton: .default(Text(L10n.ok))
            )
        }

        KeyboardTextField(text: $tempHexString, isFirstResponder: $showHexInput) {
            updateFromHex()
        }.frame(width: 0, height: 0).opacity(0)
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

            Button {} label: {
                GeometryReader { _ in
                    ZStack(alignment: .leading) {
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(
                                    red: colorComponent == .red ? 0 : red,
                                    green: colorComponent == .green ? 0 : green,
                                    blue: colorComponent == .blue ? 0 : blue
                                ),
                                Color(red: red, green: green, blue: blue),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: ColorPickerView.maximumWidth * value.wrappedValue)

                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color(red: red, green: green, blue: blue),
                                Color(
                                    red: colorComponent == .red ? 1 : red,
                                    green: colorComponent == .green ? 1 : green,
                                    blue: colorComponent == .blue ? 1 : blue
                                ),
                            ]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .opacity(0.6)
                        .padding(.leading, ColorPickerView.maximumWidth * value.wrappedValue)

                        RoundedRectangle(cornerRadius: ColorPickerView.sliderIndicatorWidth)
                            .fill(.primary)
                            .frame(width: ColorPickerView.sliderIndicatorWidth)
                            .padding(.leading, ColorPickerView.maximumWidth * value.wrappedValue - ColorPickerView.sliderIndicatorWidth / 2)
                    }
                }
            }
            .onMoveCommand(perform: { (direction: MoveCommandDirection) in
                handleMoveCommand(colorComponent: colorComponent, direction)
            })
            .buttonStyle(.card)
            .frame(height: ColorPickerView.sliderHeight)
            .opacity(focusState.wrappedValue ? 1 : 0.8)
        }
    }

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
        }
        self.color = Color(red: self.red, green: self.green, blue: self.blue)
        self.hexString = String(format: "#%02X%02X%02X", Int(255 * self.red), Int(255 * self.green), Int(255 * self.blue))
        self.tempHexString = self.hexString
    }

    private func updateFromHex() {
        guard tempHexString.hasPrefix("#"), tempHexString.count == 7 else {
            showHexError = true
            return
        }

        let hex = String(tempHexString.dropFirst())
        if let rgb = UInt32(hex, radix: 16) {
            self.red = CGFloat((rgb & 0xFF0000) >> 16) / 255
            self.green = CGFloat((rgb & 0x00FF00) >> 8) / 255
            self.blue = CGFloat(rgb & 0x0000FF) / 255
            self.color = Color(red: self.red, green: self.green, blue: self.blue)
            self.hexString = tempHexString
        } else {
            showHexError = true
        }
    }

    private func updateFromColor(color: Color) {
        self.color = color
        color.uiColor.getRed(&self.red, green: &self.green, blue: &self.blue, alpha: nil)

        self.hexString = String(format: "#%02X%02X%02X", Int(255 * self.red), Int(255 * self.green), Int(255 * self.blue))
        self.tempHexString = self.hexString
    }

    init(color: Binding<Color>) {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
        color.wrappedValue.uiColor.getRed(&r, green: &g, blue: &b, alpha: nil)
        let hexString = String(format: "#%02X%02X%02X", Int(255 * r), Int(255 * g), Int(255 * b))

        self.red = r
        self.green = g
        self.blue = b
        self.hexString = hexString
        self.tempHexString = hexString
        self._color = color
    }
}

private struct KeyboardTextField: UIViewRepresentable {
    @Binding
    var text: String
    @Binding
    var isFirstResponder: Bool
    var onCommit: (() -> Void)? = nil

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

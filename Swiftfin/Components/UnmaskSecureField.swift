//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: use _UIHostingView for button animation workaround?
//       - have a nice animation for toggle

struct UnmaskSecureField: UIViewRepresentable {

    @Binding
    private var text: String

    private let onReturn: () -> Void
    private let title: String

    init(
        _ title: String,
        text: Binding<String>,
        onReturn: @escaping () -> Void = {}
    ) {
        self._text = text
        self.title = title
        self.onReturn = onReturn
    }

    func makeUIView(context: Context) -> UITextField {

        let textField = UITextField()
        textField.font = context.environment.font?.uiFont ?? UIFont.preferredFont(forTextStyle: .body)
        textField.adjustsFontForContentSizeCategory = true
        textField.isSecureTextEntry = true
        textField.keyboardType = .asciiCapable
        textField.placeholder = title
        textField.text = text
        textField.addTarget(
            context.coordinator,
            action: #selector(Coordinator.textDidChange),
            for: .editingChanged
        )

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(
            context.coordinator,
            action: #selector(Coordinator.buttonPressed),
            for: .touchUpInside
        )
        button.setImage(
            UIImage(systemName: "eye.fill"),
            for: .normal
        )

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 50),
        ])

        textField.rightView = button
        textField.rightViewMode = .always

        context.coordinator.button = button
        context.coordinator.onReturn = onReturn
        context.coordinator.textField = textField
        context.coordinator.textDidChange()
        context.coordinator.textBinding = _text

        textField.delegate = context.coordinator

        return textField
    }

    func updateUIView(_ textField: UITextField, context: Context) {
        if text != textField.text {
            textField.text = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator: NSObject, UITextFieldDelegate {

        weak var button: UIButton?
        weak var textField: UITextField?
        var textBinding: Binding<String> = .constant("")
        var onReturn: () -> Void = {}

        @objc
        func buttonPressed() {
            guard let textField else { return }
            textField.toggleSecureEntry()

            let eye = textField.isSecureTextEntry ? "eye.fill" : "eye.slash"
            button?.setImage(UIImage(systemName: eye), for: .normal)
        }

        @objc
        func textDidChange() {
            guard let textField, let text = textField.text else { return }
            button?.isEnabled = !text.isEmpty
            textBinding.wrappedValue = text
        }

        func textFieldShouldReturn(_ textField: UITextField) -> Bool {
            onReturn()
            return true
        }
    }
}

private extension UITextField {

    // https://stackoverflow.com/a/48115361
    func toggleSecureEntry() {

        isSecureTextEntry.toggle()

        if let existingText = text, isSecureTextEntry {
            deleteBackward()

            if let textRange = textRange(from: beginningOfDocument, to: endOfDocument) {
                replace(textRange, withText: existingText)
            }
        }

        if let existingSelectedTextRange = selectedTextRange {
            selectedTextRange = nil
            selectedTextRange = existingSelectedTextRange
        }
    }
}

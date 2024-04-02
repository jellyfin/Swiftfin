//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct UnmaskSecureField: UIViewRepresentable {

    @Binding
    private var text: String

    let title: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    func makeUIView(context: Context) -> some UIView {

        let textField = UITextField()
        textField.isSecureTextEntry = true
        textField.keyboardType = .asciiCapable
        textField.placeholder = title
        textField.text = text
        textField.addTarget(context.coordinator, action: #selector(Coordinator.textDidChange), for: .editingChanged)

        let button = UIButton(type: .custom)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(context.coordinator, action: #selector(Coordinator.buttonPressed), for: .touchUpInside)
        button.setImage(UIImage(systemName: "eye.fill"), for: .normal)

        NSLayoutConstraint.activate([
            button.heightAnchor.constraint(equalToConstant: 50),
            button.widthAnchor.constraint(equalToConstant: 50),
        ])

        textField.rightView = button
        textField.rightViewMode = .always

        context.coordinator.button = button
        context.coordinator.textField = textField
        context.coordinator.textDidChange()
        context.coordinator.textBinding = _text

        return textField
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    class Coordinator {

        weak var button: UIButton?
        weak var textField: UITextField?
        var textBinding: Binding<String> = .constant("")

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

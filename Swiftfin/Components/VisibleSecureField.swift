//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct VisibleSecureField: View {

    @Binding
    private var text: String

    @StateObject
    private var helper = Helper()

    let title: String

    init(_ title: String, text: Binding<String>) {
        self.title = title
        self._text = text
    }

    var body: some View {
        SecureField(title, text: $text)
            .introspect(.textField, on: .iOS(.v15), .iOS(.v16), .iOS(.v17)) { textField in
                let button = UIButton(type: .custom)
                button.addTarget(helper, action: #selector(Helper.buttonPressed), for: .touchUpInside)
                button.setImage(UIImage(systemName: "eye.fill"), for: .normal)

                textField.rightView = button
                textField.rightViewMode = .always

                helper.button = button
                helper.textField = textField

                helper.textDidChange(text)
            }
            .onChange(of: text) { newValue in
                helper.textDidChange(newValue)
            }
    }

    private class Helper: ObservableObject {

        weak var button: UIButton?
        weak var textField: UITextField?

        @objc
        func buttonPressed() {
            textField?.isSecureTextEntry.toggle()

            let eye = textField?.isSecureTextEntry ?? false ? "eye.fill" : "eye.slash"
            button?.setImage(UIImage(systemName: eye), for: .normal)
        }

        func textDidChange(_ text: String) {
            button?.isEnabled = text.isNotEmpty
        }
    }
}

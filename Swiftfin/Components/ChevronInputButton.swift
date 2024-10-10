//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Foundation
import SwiftUI

struct ChevronInputButton<Value>: View where Value: LosslessStringConvertible & Equatable {

    @Binding
    private var value: Value
    @State
    private var temporaryInputValue: String
    @State
    private var isSelected = false

    private let title: String
    private let description: String?
    private let subtitle: String
    private let helpText: String?
    private let keyboardType: UIKeyboardType

    init(
        title: String,
        subtitle: String,
        description: String? = nil,
        helpText: String? = nil,
        value: Binding<Value>,
        keyboard: UIKeyboardType = .default
    ) {
        self.title = title
        self.subtitle = subtitle
        self.description = description
        self.helpText = helpText
        self._value = value
        self._temporaryInputValue = State(initialValue: value.wrappedValue.description)
        self.keyboardType = keyboard
    }

    // MARK: - Body

    // TODO: Likely want to redo this but better. Needed in
    var body: some View {
        ChevronButton(
            title,
            subtitle: subtitle
        )
        .onSelect {
            temporaryInputValue = value.description
            isSelected = true
        }
        .alert(title, isPresented: $isSelected) {
            TextField(helpText ?? title, text: $temporaryInputValue)
                .keyboardType(keyboardType)

            Button(L10n.save) {
                if let newValue = Value(temporaryInputValue) {
                    value = newValue
                }
                isSelected = false
            }
            Button(L10n.cancel, role: .cancel) {
                isSelected = false
            }
        } message: {
            if let description = description {
                Text(description)
            }
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ListRowToggleCheckbox: View {

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Properties

    private let title: Text
    private let isOn: Binding<Bool>

    // MARK: - Body

    var body: some View {
        Button(action: {
            isOn.wrappedValue.toggle()
        }) {
            HStack {
                title
                    .foregroundStyle(isFocused ? .black : .white)
                    .padding(.leading, 4)

                Spacer()

                Image(systemName: isOn.wrappedValue ? "checkmark.circle.fill" : "circle")
                    .font(.body.weight(.regular))
                    .foregroundStyle(isFocused ? .black : .secondary)
                    .brightness(isFocused ? 0.4 : 0)
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isFocused ? Color.white : Color.clear)
            )
            .scaleEffect(isFocused ? 1.04 : 1.0)
            .animation(.easeInOut(duration: 0.125), value: isFocused)
        }
//        .buttonStyle(.plain)
        .listRowInsets(.zero)
        .focused($isFocused)
    }
}

// MARK: - Initializers

extension ListRowToggleCheckbox {

    init(_ title: String, isOn: Binding<Bool>) {
        self.title = Text(title)
        self.isOn = isOn
    }

    init(_ title: Text, isOn: Binding<Bool>) {
        self.title = title
        self.isOn = isOn
    }
}

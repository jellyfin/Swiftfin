//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ItemView {
    struct ActionButton: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected
        @FocusState
        private var isFocused: Bool

        let size: CGFloat = 50
        let icon: String
        let selectedIcon: String
        let color: Color
        let onSelect: () -> Void

        // MARK: - Body

        var body: some View {
            Button(action: {
                onSelect()
            }) {
                foregroundIcon
            }
            .buttonStyle(BorderlessFocus(isFocused: $isFocused))
            .focused($isFocused)
            .padding(.vertical)
        }

        // MARK: - Foreground Icon

        private var foregroundIcon: some View {
            Image(systemName: isSelected ? selectedIcon : icon)
                .frame(width: size, height: size)
                .foregroundStyle(
                    isFocused ? .black : .primary,
                    isFocused ? (isSelected ? color : .black) : (isSelected ? color : .primary)
                )
                .font(.title3)
                .shadow(color: isFocused || isSelected ? .clear : .black.opacity(0.3), radius: 2, x: 0, y: 2)
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension LetterPickerBar {

    struct LetterPickerButton: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

        @FocusState
        private var isFocused: Bool

        let letter: ItemLetter
        let action: () -> Void

        private var foregroundStyle: Color {
            if isFocused {
                Color.primary.overlayColor
            } else if isSelected {
                accentColor.overlayColor
            } else {
                UIDevice.isTV ? Color.primary : accentColor
            }
        }

        private var isGlassVisible: Bool {
            isFocused || isSelected
        }

        private var glassTint: Color {
            isFocused ? .primary : accentColor
        }

        var body: some View {
            Button(action: action) {
                Text(letter.value)
                    .foregroundStyle(foregroundStyle)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .backport
                    .glassEffect(
                        isGlassVisible ? .regular.selection(
                            tint: glassTint,
                            foregroundColor: glassTint.overlayColor
                        ) : .identity,
                        in: .rect(cornerRadius: 5)
                    )
                    .isSelected(isGlassVisible)
            }
            .buttonStyle(.borderless)
            .backport
            .buttonBorderShape(.roundedRectangle)
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.2 : 1)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
        }
    }
}

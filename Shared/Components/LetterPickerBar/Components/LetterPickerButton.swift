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
        let viewModel: FilterViewModel

        private var foregroundStyle: Color {
            if isFocused {
                Color.primary.overlayColor
            } else if isSelected {
                accentColor.overlayColor
            } else {
                Color.primary
            }
        }

        private var backgroundStyle: Color {
            if isFocused {
                Color.primary
            } else if isSelected {
                accentColor
            } else {
                .clear
            }
        }

        var body: some View {
            Button {
                if viewModel.currentFilters.letter.contains(letter) {
                    viewModel.currentFilters.letter = []
                } else {
                    viewModel.currentFilters.letter = [letter]
                }
            } label: {
                label
            }
            .buttonStyle(.borderless)
            .if(UIDevice.isTV) { view in
                view
                    .focused($isFocused)
                    .scaleEffect(isFocused ? 1.2 : 1)
                    .animation(.easeInOut(duration: 0.15), value: isFocused)
            }
        }

        @ViewBuilder
        private var label: some View {
            if UIDevice.isTV {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(backgroundStyle)
                        .if(isFocused || isSelected) { background in
                            background
                                .posterShadow()
                        }

                    Text(letter.value)
                        .font(LetterPickerBar.font)
                        .foregroundStyle(foregroundStyle)
                        .if(!isFocused && !isSelected) { character in
                            character
                                .posterShadow()
                        }
                }
            } else {
                Text(letter.value)
                    .font(.footnote)
                    .foregroundStyle(isSelected ? accentColor.overlayColor : accentColor.opacity(0.75))
                    .frame(width: 16, height: 16)
                    .backport
                    .glassEffect(
                        isSelected ? .regular.tint(accentColor) : .identity,
                        in: .circle
                    )
            }
        }
    }
}

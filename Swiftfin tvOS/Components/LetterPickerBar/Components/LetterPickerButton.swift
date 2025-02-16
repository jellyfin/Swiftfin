//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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
        private var isFocused

        private let letter: ItemLetter
        private let size: CGFloat
        private let viewModel: FilterViewModel

        init(letter: ItemLetter, size: CGFloat, viewModel: FilterViewModel) {
            self.letter = letter
            self.size = size
            self.viewModel = viewModel
        }

        var body: some View {
            Button {
                if viewModel.currentFilters.letter.contains(letter) {
                    viewModel.send(.update(.letter, []))
                } else {
                    viewModel.send(.update(.letter, [ItemLetter(stringLiteral: letter.value).asAnyItemFilter]))
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(isFocused ? .lightGray : (isSelected ? accentColor : .clear))
                        .shadow(color: isFocused || isSelected ? .black : .clear, radius: 2, x: 0, y: 2)
                        .frame(width: size, height: size)

                    Text(letter.value)
                        .font(.footnote.weight(.regular))
                        .foregroundStyle(isFocused ? .black : (isSelected ? .white : .white))
                        .shadow(color: isFocused || isSelected ? .clear : .black, radius: 2, x: 0, y: 2)
                        .frame(width: size, height: size, alignment: .center)
                }
            }
            .buttonStyle(.borderless)
            .focused($isFocused)
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension LetterPickerBar {

    struct LetterPickerButton: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

        private let letter: ItemLetter
        private let viewModel: FilterViewModel

        init(letter: ItemLetter, viewModel: FilterViewModel) {
            self.letter = letter
            self.viewModel = viewModel
        }

        var body: some View {
            Button {
                if !viewModel.currentFilters.letter.contains(letter) {
                    viewModel.currentFilters.letter = [ItemLetter(stringLiteral: letter.value)]
                } else {
                    viewModel.currentFilters.letter = []
                }
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 5)
                        .foregroundStyle(isSelected ? accentColor : Color.clear)

                    Text(letter.value)
                        .font(.headline)
                        .foregroundStyle(isSelected ? accentColor.overlayColor : accentColor)
                }
                .frame(width: 20, height: 20)
            }
            .frame(width: 50, height: 20)
        }
    }
}

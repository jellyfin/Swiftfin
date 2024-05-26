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

        private let filterLetter: ItemLetter
        private let viewModel: FilterViewModel

        init(filterLetter: ItemLetter, viewModel: FilterViewModel) {
            self.filterLetter = filterLetter
            self.viewModel = viewModel
        }

        var body: some View {
            Button {
                if !viewModel.currentFilters.letter.contains(filterLetter) {
                    viewModel.currentFilters.letter = [ItemLetter(stringLiteral: filterLetter.value)]
                } else {
                    viewModel.currentFilters.letter = []
                }
            } label: {
                Text(
                    filterLetter.value
                )
                .environment(\.isSelected, viewModel.currentFilters.letter.contains(filterLetter))
                .font(.headline)
                .frame(width: 15, height: 15)
                .foregroundStyle(isSelected ? accentColor.overlayColor : accentColor)
                .padding(.vertical, 2)
                .fixedSize(horizontal: false, vertical: true)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: 20, height: 20)
                        .foregroundStyle(isSelected ? accentColor.opacity(0.5) : Color.clear)
                }
            }
        }
    }
}

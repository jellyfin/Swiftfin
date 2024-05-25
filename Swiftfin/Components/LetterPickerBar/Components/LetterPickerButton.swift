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

        private let filterLetter: String
        private let activated: Bool
        private let viewModel: FilterViewModel
        private var onSelect: () -> Void

        var body: some View {
            Button {
                if viewModel.currentFilters.letter.first?.value != filterLetter {
                    viewModel.currentFilters.letter = [ItemLetter(stringLiteral: filterLetter)]
                } else {
                    viewModel.currentFilters.letter = []
                }
            } label: {
                Text(
                    filterLetter
                )
                .font(.headline)
                .frame(width: 15, height: 15)
                .foregroundColor(activated ? Color.white : accentColor)
                .padding(.vertical, 2)
                .fixedSize(horizontal: false, vertical: true)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: 20, height: 20)
                        .foregroundColor(activated ? accentColor.opacity(0.5) : Color.clear)
                }
            }
        }
    }
}

extension LetterPickerBar.LetterPickerButton {
    init(
        filterLetter: String,
        activated: Bool,
        viewModel: FilterViewModel
    ) {
        self.init(
            filterLetter: filterLetter,
            activated: activated,
            viewModel: viewModel,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

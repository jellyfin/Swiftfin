//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension AlphaPickerBar {

    struct AlphaPickerButton: View {

        @FocusState
        var isFocused: Bool

        @Default(.accentColor)
        private var accentColor

        private let filterLetter: String
        private let activated: Bool
        private let viewModel: FilterViewModel
        private var onSelect: () -> Void

        var body: some View {
            Button {
                if viewModel.currentFilters.alphaPicker.compactMap(
                    \.id
                ).first != String(filterLetter) {
                    viewModel.currentFilters.alphaPicker = [ItemFilters.Filter(
                        displayTitle: filterLetter,
                        id: filterLetter,
                        filterName: "alphaPicker"
                    )]
                } else {
                    viewModel.currentFilters.alphaPicker = []
                }
            } label: {
                Text(
                    filterLetter
                )
                .font(.headline)
                .frame(width: 35, height: 35)
                .foregroundColor(activated ? Color.white : accentColor)
                .background {
                    RoundedRectangle(cornerRadius: 5)
                        .frame(width: 80, height: 40)
                        .foregroundColor(activated ? accentColor.opacity(0.5) : Color.clear)
                }
            }
            .buttonStyle(PlainButtonStyle())
        }
    }
}

extension AlphaPickerBar.AlphaPickerButton {
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

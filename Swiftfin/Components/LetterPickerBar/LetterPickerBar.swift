//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LetterPickerBar: View {
    @ObservedObject
    private var viewModel: FilterViewModel

    init(viewModel: FilterViewModel) {
        self.viewModel = viewModel
    }

    @ViewBuilder
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            ForEach(ItemLetter.allCases, id: \.hashValue) { filterLetter in
                LetterPickerButton(
                    filterLetter: filterLetter,
                    viewModel: viewModel
                )
                .environment(\.isSelected, viewModel.currentFilters.letter.contains(filterLetter))
                .frame(maxWidth: .infinity)
            }
            Spacer()
        }
        .scrollOnOverflow()
        .frame(width: 30, alignment: .center)
    }
}

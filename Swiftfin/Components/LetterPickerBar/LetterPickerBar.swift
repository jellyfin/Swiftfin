//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LetterPickerBar: View {

    @ObservedObject
    var viewModel: FilterViewModel

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            ForEach(ItemLetter.allCases, id: \.hashValue) { filterLetter in
                LetterPickerButton(
                    letter: filterLetter,
                    size: LetterPickerBar.size,
                    viewModel: viewModel
                )
                .environment(\.isSelected, viewModel.currentFilters.letter.contains(filterLetter))
            }

            Spacer()
        }
        .scrollIfLargerThanContainer()
        .frame(width: LetterPickerBar.size, alignment: .center)
    }

    // MARK: - Letter Button Size

    static var size: CGFloat {
        String().height(
            withConstrainedWidth: CGFloat.greatestFiniteMagnitude,
            font: UIFont.preferredFont(
                forTextStyle: .headline
            )
        )
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LetterPickerBar: View {

    @Default(.accentColor)
    private var accentColor

    @ObservedObject
    var viewModel: FilterViewModel

    @ViewBuilder
    var body: some View {
        VStack(spacing: 0) {
            ForEach(ItemLetter.allCases, id: \.hashValue) { letter in
                let isSelected = viewModel.currentFilters.letter.contains(letter)

                Button {
                    if viewModel.currentFilters.letter.contains(letter) {
                        viewModel.currentFilters.letter = []
                    } else {
                        viewModel.currentFilters.letter = [letter]
                    }
                } label: {
                    ZStack {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(isSelected ? accentColor : Color.clear)

                        Text(letter.value)
                            .font(.headline)
                            .foregroundStyle(isSelected ? accentColor.overlayColor : accentColor)
                    }
                    .frame(width: 30, height: 30)
                }
            }
        }
        .frame(maxHeight: .infinity)
        .scrollIfLargerThanContainer()
        .frame(width: 30)
    }

    private var fontLineHeight: CGFloat {
        UIFont.preferredFont(forTextStyle: .headline).lineHeight
    }
}

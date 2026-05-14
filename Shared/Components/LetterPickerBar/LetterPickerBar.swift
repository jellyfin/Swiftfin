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

    @ObservedObject
    var viewModel: FilterViewModel

    @FocusState
    private var focusedLetter: ItemLetter?

    @State
    private var letterSize: CGSize = .zero

    // Largest letter +1p on either side
    private var dimension: CGFloat {
        max(letterSize.width, letterSize.height) + 2
    }

    private var buttonSpacing: CGFloat {
        UIDevice.isTV ? dimension * 0.1 : 0
    }

    static var font: Font {
        UIDevice.isTV ? .system(size: 22, weight: .semibold) : .headline
    }

    var body: some View {
        VStack(alignment: .center, spacing: buttonSpacing) {
            ForEach(ItemLetter.allCases, id: \.hashValue) { filterLetter in
                LetterPickerButton(letter: filterLetter, viewModel: viewModel)
                    .frame(width: dimension, height: dimension)
                    .focused($focusedLetter, equals: filterLetter)
                    .isSelected(viewModel.currentFilters.letter.contains(filterLetter))
            }
        }
        .scrollIfLargerThanContainer()
        .frame(width: dimension)
        .focusSection()
        .background {
            ZStack {
                ForEach(ItemLetter.allCases, id: \.hashValue) { letter in
                    Text(letter.value)
                        .font(LetterPickerBar.font)
                }
            }
            .hidden()
            .allowsHitTesting(false)
            .fixedSize()
            .trackingSize($letterSize)
        }
        #if os(tvOS)
        .defaultFocus(
            $focusedLetter,
            viewModel.currentFilters.letter.first
                ?? ItemLetter.allCases.first
                ?? ItemLetter(value: "#"),
            priority: focusedLetter == nil ? .userInitiated : .automatic
        )
        #endif
    }
}

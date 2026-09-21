//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct LetterPickerActiveLetterKey: PreferenceKey {

    static var defaultValue: ItemLetter?

    static func reduce(value: inout ItemLetter?, nextValue: () -> ItemLetter?) {
        value = nextValue() ?? value
    }
}

extension LetterPickerBar {

    struct LetterPickerCallout: View {

        let letter: ItemLetter

        var body: some View {
            AlternateLayoutView {
                ZStack {
                    ForEach(ItemLetter.allCases, id: \.value) { letter in
                        Text(letter.value)
                    }
                }
                .hidden()
                .allowsHitTesting(false)
                .fixedSize()
            } content: { size in
                Text(letter.value)
                    .frame(width: size.width, height: size.height)
                    .padding(16)
                    .backport
                    .glassEffect(
                        .regular,
                        in: .rect(cornerRadius: UIDevice.isTV ? 12 : 8)
                    )
            }
        }
    }
}

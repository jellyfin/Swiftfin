//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct LetterPickerActiveLetterKey: PreferenceKey {

    static var defaultValue: ItemLetter?

    static func reduce(value: inout ItemLetter?, nextValue: () -> ItemLetter?) {
        value = nextValue() ?? value
    }
}

extension LetterPickerBar {

    struct LetterPickerCallout: View {

        @Default(.accentColor)
        private var accentColor

        @State
        private var letterSize: CGSize = .zero

        let letter: ItemLetter

        private var buttonSize: CGFloat {
            max(letterSize.width, letterSize.height) + 16
        }

        var body: some View {
            Text(letter.value)
                .foregroundStyle(UIDevice.isTV ? Color.primary : accentColor)
                .frame(width: buttonSize, height: buttonSize)
                .backport
                .glassEffect(
                    .regular,
                    in: .rect(cornerRadius: UIDevice.isTV ? 12 : 8)
                )
                .background {
                    ZStack {
                        ForEach(ItemLetter.allCases, id: \.value) { letter in
                            Text(letter.value)
                        }
                    }
                    .hidden()
                    .allowsHitTesting(false)
                    .fixedSize()
                    .trackingSize($letterSize)
                }
        }
    }
}

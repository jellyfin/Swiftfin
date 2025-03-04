//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Combine
import SwiftUI

struct LibraryFilterModifier<Filters: View, Letters: View>: ViewModifier {

    // MARK: - Filter Views

    let filters: () -> Filters
    let letters: () -> Letters?

    // MARK: - Focus State

    @FocusState
    private var isContentFocused: Bool

    // MARK: - State Variables

    @State
    private var safeArea: EdgeInsets = .zero

    // MARK: - Body

    func body(content: Content) -> some View {
        ZStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, 100)
                .padding(.trailing, LetterPickerBar.size + 20)
                .focusSection()

            HStack(spacing: 0) {
                filters()
                    .frame(alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.bottom, safeArea.bottom)
                    .padding(.top, safeArea.top)
                    .focusSection()

                Spacer()

                if let letterPickerBar = letters() {
                    letterPickerBar
                        .frame(alignment: .leading)
                        .padding(.trailing, 20)
                        .padding(.bottom, safeArea.bottom)
                        .padding(.top, safeArea.top)
                        .focusSection()
                }
            }
        }
    }
}

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

    let filters: () -> Filters
    let letters: () -> Letters?

    @State
    private var safeArea: EdgeInsets = .zero

    private let collapsedWidth: CGFloat = 75
    private let expandedWidth: CGFloat = 200

    @FocusState
    private var isFilterFocused: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.leading, collapsedWidth + 20)
                .padding(.trailing, collapsedWidth + 20)

            HStack(spacing: 0) {
                filters()
                    .frame(width: (isFilterFocused ? expandedWidth : collapsedWidth) + 10, alignment: .leading)
                    .padding(.leading, 20)
                    .padding(.bottom, safeArea.bottom)
                    .padding(.top, safeArea.top)
                    .focusSection()
                    .focused($isFilterFocused)

                Spacer()

                if let letterPickerBar = letters() {
                    letterPickerBar
                        .frame(width: collapsedWidth, alignment: .center)
                        .padding(.trailing, 20)
                        .padding(.bottom, safeArea.bottom)
                        .padding(.top, safeArea.top)
                }
            }
        }
    }
}

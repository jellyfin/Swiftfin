//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct PrimaryButton: View {

    // MARK: - Accent Color

    @Default(.accentColor)
    private var accentColor

    // MARK: - Focus State

    @FocusState
    private var isFocused

    // MARK: - Primary Button Variables

    private let title: String
    private var onSelect: () -> Void

    // MARK: - body

    var body: some View {
        ZStack {
            ListRowButton(title) {
                onSelect()
            }
            .focused($isFocused)
            .foregroundStyle(accentColor.overlayColor, isFocused ? Color.jellyfinPurple : Color.gray)
        }
        .frame(maxWidth: 500)
        .frame(height: 75)
    }
}

extension PrimaryButton {

    init(title: String) {
        self.init(
            title: title,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

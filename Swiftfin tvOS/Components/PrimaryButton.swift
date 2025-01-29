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

    // MARK: - Defaults

    @Default(.accentColor)
    private var accentColor

    // MARK: - Environment

    @Environment(\.isEnabled)
    private var isEnabled

    // MARK: - Focus State

    @FocusState
    private var isFocused: Bool

    // MARK: - Button Variables

    private let title: String
    private var onSelect: () -> Void

    // MARK: - Body

    var body: some View {
        Button {
            onSelect()
        } label: {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(accentColor)

                if !isEnabled {
                    Color.black.opacity(0.5)
                } else if isFocused {
                    Color.white.opacity(0.25)
                }

                Text(title)
                    .fontWeight(.bold)
                    .foregroundStyle(isFocused ? Color.black : accentColor.overlayColor)
            }
        }
        .buttonStyle(.card)
        .frame(height: 75)
        .frame(maxWidth: 750)
        .focused($isFocused)
    }
}

extension PrimaryButton {

    // MARK: - Initializer

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

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ItemView {

    struct ActionMenu<Content: View>: View {

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        // MARK: - Menu Items

        @ViewBuilder
        let menuItems: Content

        // MARK: - Body

        var body: some View {
            Menu {
                menuItems
            } label: {
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isFocused ? Color.white : Color.white.opacity(0.5))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.clear, lineWidth: 2)
                        )

                    Label(L10n.menuButtons, systemImage: "ellipsis")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .labelStyle(.iconOnly)
                        .rotationEffect(.degrees(90))
                }
            }
            .focused($isFocused)
            .scaleEffect(isFocused ? 1.20 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: isFocused)
            .menuStyle(.borderlessButton)
        }
    }
}

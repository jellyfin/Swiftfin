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

    struct ActionButton: View {

        // MARK: - Environment Objects

        @Environment(\.isSelected)
        private var isSelected

        // MARK: - Focus State

        @FocusState
        private var isFocused: Bool

        // MARK: - Item Variables

        let title: String
        let icon: String
        let selectedIcon: String

        // MARK: - Item Actions

        let onSelect: () -> Void

        // MARK: - Body

        var body: some View {
            Button(action: onSelect) {
                ZStack {
                    if isSelected {
                        Rectangle()
                            .fill(
                                isFocused ? AnyShapeStyle(HierarchicalShapeStyle.primary) :
                                    AnyShapeStyle(HierarchicalShapeStyle.primary.opacity(0.5))
                            )
                    } else {
                        Rectangle()
                            .fill(isFocused ? Color.white : Color.white.opacity(0.5))
                    }

                    Label(title, systemImage: isSelected ? selectedIcon : icon)
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundStyle(.black)
                        .labelStyle(.iconOnly)
                }
            }
            .padding(0)
            .focused($isFocused)
            .buttonStyle(.card)
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension NavigationBarFilterDrawer {

    struct FilterDrawerButton: View {

        @Default(.accentColor)
        private var accentColor

        @Environment(\.isSelected)
        private var isSelected

        private let systemName: String?
        private let title: String
        private var onSelect: () -> Void

        var body: some View {
            Button {
                onSelect()
            } label: {
                HStack(spacing: 2) {
                    Group {
                        if let systemName = systemName {
                            Image(systemName: systemName)
                        } else {
                            Text(title)
                        }
                    }
                    .font(.footnote.weight(.semibold))

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background {
                    Capsule()
                        .foregroundColor(isSelected ? accentColor : Color(UIColor.secondarySystemFill))
                        .opacity(0.5)
                }
                .overlay {
                    Capsule()
                        .stroke(isSelected ? accentColor : Color(UIColor.secondarySystemFill), lineWidth: 1)
                }
            }
        }
    }
}

extension NavigationBarFilterDrawer.FilterDrawerButton {

    init(title: String) {
        self.init(
            systemName: nil,
            title: title,
            onSelect: {}
        )
    }

    init(systemName: String) {
        self.init(
            systemName: systemName,
            title: "",
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

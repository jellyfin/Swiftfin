//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension TVFilterDrawer {

    struct TVFilterButton: View {

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
                HStack(spacing: 8) {
                    Group {
                        if let systemName = systemName {
                            Image(systemName: systemName)
                        } else {
                            Text(title)
                        }
                    }
                    .font(.title3.weight(.semibold))

                    if systemName == nil {
                        Image(systemName: "chevron.down")
                            .font(.caption)
                    }
                }
                .foregroundColor(.primary)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background {
                    RoundedRectangle(cornerRadius: 8)
                        .foregroundColor(isSelected ? accentColor : Color.gray.opacity(0.3))
                        .opacity(0.3)
                }
                .overlay {
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(isSelected ? accentColor : Color.gray.opacity(0.5), lineWidth: 2)
                }
            }
            .buttonStyle(.plain)
            .scaleEffect(isSelected ? 1.05 : 1.0)
            .animation(.easeInOut(duration: 0.2), value: isSelected)
        }
    }
}

extension TVFilterDrawer.TVFilterButton {

    init(title: String) {
        self.init(
            systemName: nil,
            title: title,
            onSelect: {}
        )
    }

    init(systemName: String, title: String) {
        self.init(
            systemName: systemName,
            title: title,
            onSelect: {}
        )
    }

    func onSelect(_ action: @escaping () -> Void) -> Self {
        copy(modifying: \.onSelect, with: action)
    }
}

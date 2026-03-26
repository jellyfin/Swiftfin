//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension NavigationBarFilterDrawer {

    struct FilterDrawerButton: View {

        private let systemName: String?
        private let title: String
        private var onSelect: () -> Void

        var body: some View {
            Button {
                onSelect()
            } label: {
                HStack(spacing: 2) {
                    Group {
                        if let systemName {
                            Image(systemName: systemName)
                        } else {
                            Text(title)
                        }
                    }

                    Image(systemName: "chevron.down")
                        .font(.caption)
                }
            }
            .buttonStyle(.toolbarCapsule)
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

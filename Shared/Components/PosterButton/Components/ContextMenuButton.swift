//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Factory
import JellyfinAPI
import SwiftUI

extension PosterButton {

    struct ContextMenuButton: View {

        // MARK: - Button Variables

        private let role: ButtonRole?
        private let title: String
        private let icon: String
        private let action: () -> Void

        // MARK: - Initializer

        init(_ title: String, icon: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
            self.role = role
            self.title = title
            self.icon = icon
            self.action = action
        }

        // MARK: - Body

        var body: some View {
            Button(role: role, action: action) {
                HStack {
                    Text(title)
                    Spacer()
                    Image(systemName: icon)
                }
                .backport
                .fontWeight(.semibold)
            }
        }
    }
}

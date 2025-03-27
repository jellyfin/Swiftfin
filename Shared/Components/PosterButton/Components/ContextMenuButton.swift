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
        private let subtitle: String?
        private let icon: String
        private let action: () -> Void

        // MARK: - Initializer

        init(_ title: String, subtitle: String? = nil, icon: String, role: ButtonRole? = nil, action: @escaping () -> Void) {
            self.title = title
            self.subtitle = subtitle
            self.icon = icon
            self.role = role
            self.action = action
        }

        // MARK: - Body

        var body: some View {
            Button(role: role, action: action) {
                HStack {
                    buttonText

                    Image(systemName: icon)
                        .foregroundStyle(.primary)
                }
                .backport
                .fontWeight(.semibold)
            }
        }

        // MARK: - Button Text

        private var buttonText: Text {
            if let subtitle {
                return Text("\(title) • \(subtitle)")
            } else {
                return Text(title)
            }
        }
    }
}

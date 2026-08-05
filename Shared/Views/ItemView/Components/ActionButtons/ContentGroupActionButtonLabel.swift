//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ContentGroupActionButtonLabel: View {

    @ViewContextContains(.isInMenu)
    private var isInMenu

    private let title: String
    private let systemImage: String
    private let activeColor: Color?
    private let isActive: Bool

    init(
        title: String,
        systemImage: String,
        activeColor: Color? = nil,
        isActive: Bool = false
    ) {
        self.title = title
        self.systemImage = systemImage
        self.activeColor = activeColor
        self.isActive = isActive
    }

    init(
        _ button: ContentGroupActionButton,
        systemImage: String? = nil,
        isActive: Bool = false
    ) {
        self.init(
            title: button.displayTitle,
            systemImage: systemImage ?? button.systemImage,
            activeColor: button.activeColor,
            isActive: isActive
        )
    }

    private var tint: Color {
        guard isActive, let activeColor else {
            return .gray.opacity(0.15)
        }

        return activeColor
    }

    private var iconFont: Font {
        UIDevice.isTV ? .system(size: 30) : .title3
    }

    var body: some View {
        if isInMenu {
            Label(title, systemImage: systemImage)
        } else {
            Label {
                Text(title)
            } icon: {
                Image(systemName: systemImage)
                    .font(iconFont)
            }
            .labelStyle(.iconOnly)
            .padding(UIDevice.isTV ? 16 : 8)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .backport
            .glassEffect(
                .regular.selection(
                    tint: tint,
                    foregroundColor: .primary
                ),
                in: .capsule
            )
        }
    }
}

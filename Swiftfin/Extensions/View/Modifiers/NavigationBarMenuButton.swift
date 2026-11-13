//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavigationBarMenuButtonModifier<MenuContent: View>: ViewModifier {

    @AppTheme
    private var theme

    private let menuContent: MenuContent
    private let isLoading: Bool
    private let isHidden: Bool

    init(
        isLoading: Bool = false,
        isHidden: Bool = false,
        @ContentBuilder menuContent: () -> MenuContent
    ) {
        self.isLoading = isLoading
        self.isHidden = isHidden
        self.menuContent = menuContent()
    }

    @ContentBuilder
    func body(content: Self.Content) -> some View {
        content
            .coordinatedToolbar {
                CoordinatedToolbarItem {
                    if isLoading {
                        ProgressView()
                    }

                    if !isHidden {
                        let systemImage = if #available(iOS 26, *) {
                            "ellipsis"
                        } else {
                            "ellipsis.circle"
                        }

                        Menu(L10n.options, systemImage: systemImage) {
                            menuContent
                        }
                        .labelStyle(.iconOnly)
                        .fontWeight(.semibold)
                        .foregroundStyle(theme.accentColor)
                    }
                }
            }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct NavigationBarMenuButtonModifier<MenuContent: View>: ViewModifier {

    @Default(.accentColor)
    private var accentColor

    @State
    private var collectedMenuGroups: [MenuContentGroup] = []

    private let menuContent: MenuContent
    private let isLoading: Bool
    private let isHidden: Bool
    private let onPressed: ((Bool) -> Void)?

    init(
        isLoading: Bool = false,
        isHidden: Bool = false,
        onPressed: ((Bool) -> Void)? = nil,
        @ViewBuilder menuContent: () -> MenuContent
    ) {
        self.isLoading = isLoading
        self.isHidden = isHidden
        self.onPressed = onPressed
        self.menuContent = menuContent()
    }

    func body(content: Self.Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {

                    if isLoading {
                        ProgressView()
                    }

//                    if !isHidden, collectedMenuGroups.isNotEmpty {
                    if !isHidden {

                        let systemImage = if #available(iOS 26, *) {
                            "ellipsis"
                        } else {
                            "ellipsis.circle"
                        }

                        let foregroundStyle: Color = if #available(iOS 26, *) {
                            .primary
                        } else {
                            accentColor
                        }

                        Menu(L10n.options, systemImage: systemImage) {
                            menuContent

                            ForEach(collectedMenuGroups) { group in
                                group.content
                            }
                        }
                        .labelStyle(.iconOnly)
                        .fontWeight(.semibold)
                        .foregroundStyle(foregroundStyle)
                        .if(onPressed != nil) { view in
                            view
                                .menuStyle(.button)
                                .buttonStyle(.isPressed { isPressed in
                                    onPressed?(isPressed)
                                })
                                .tint(foregroundStyle)
                        }
                    }
                }
            }
            .onPreferenceChange(MenuContentKey.self) { newGroups in
                collectedMenuGroups = newGroups
            }
    }
}

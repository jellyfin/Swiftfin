//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
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

    init(
        isLoading: Bool = false,
        isHidden: Bool = false,
        @ViewBuilder menuContent: () -> MenuContent
    ) {
        self.isLoading = isLoading
        self.isHidden = isHidden
        self.menuContent = menuContent()
    }

    func body(content: Self.Content) -> some View {
        content
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {

                    if isLoading {
                        ProgressView()
                    }

                    if !isHidden {
                        Menu(L10n.options, systemImage: "ellipsis.circle") {
                            menuContent

                            ForEach(collectedMenuGroups) { group in
                                group.content
                            }
                        }
                        .labelStyle(.iconOnly)
                        .fontWeight(.semibold)
                        .foregroundStyle(accentColor)
                    }
                }
            }
            .onPreferenceChange(MenuContentKey.self) { newGroups in
                self.collectedMenuGroups = newGroups
            }
    }
}

struct MenuContentGroup: Identifiable, Equatable {

    let id: String
    let content: AnyView

    init(
        id: String = UUID().uuidString,
        @ViewBuilder content: () -> some View
    ) {
        self.id = id
        self.content = AnyView(content())
    }

    static func == (lhs: MenuContentGroup, rhs: MenuContentGroup) -> Bool {
        lhs.id == rhs.id
    }
}

struct MenuContentKey: PreferenceKey {

    static var defaultValue: [MenuContentGroup] = []

    static func reduce(value: inout [MenuContentGroup], nextValue: () -> [MenuContentGroup]) {
        value.append(contentsOf: nextValue())
    }
}

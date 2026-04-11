//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: Figure out workaround with extra padding from `Menu`

struct ConditionalMenu<Label: View, MenuContent: View>: View {

    private let action: () -> Void
    private let isMenu: Bool
    private let label: () -> Label
    private let menuContent: () -> MenuContent

    var body: some View {
        if isMenu {
            Menu(
                content: menuContent,
                label: label
            )
        } else {
            Button(
                action: action,
                label: label
            )
        }
    }
}

extension ConditionalMenu {

    init<V>(
        tracking data: V?,
        action: @escaping (V) -> Void,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder label: @escaping () -> Label
    ) where V: Identifiable {
        self.action = {
            guard let data else { return }
            action(data)
        }
        self.isMenu = data == nil
        self.label = label
        self.menuContent = menuContent
    }

    init(
        isMenu: Bool,
        action: @escaping () -> Void,
        @ViewBuilder menuContent: @escaping () -> MenuContent,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.action = action
        self.isMenu = isMenu
        self.label = label
        self.menuContent = menuContent
    }
}

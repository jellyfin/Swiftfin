//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct NavigationBarCloseButtonModifier: ViewModifier {

    @Default(.accentColor)
    private var accentColor

    let disabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .cancellationAction) {
                Button(L10n.close, systemImage: "xmark", action: action)
                    .labelStyle(.iconOnly)
                    .font(.caption)
                    .fontWeight(.bold)
                    .frame(width: 30, height: 30)
                    .menuStyle(.button)
                    .buttonStyle(.tintedMaterial(tint: Color.gray.opacity(0.3), foregroundColor: accentColor))
                    .clipShape(.circle)
                    .isSelected(true)
                    .disabled(disabled)
            }
        }
    }
}

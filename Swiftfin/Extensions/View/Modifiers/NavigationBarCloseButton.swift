//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavigationBarCloseButtonModifier: ViewModifier {

    @AppTheme
    private var theme

    let disabled: Bool
    let action: () -> Void

    @ContentBuilder
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                if #available(iOS 26, *) {
                    Button(role: .close, action: action)
                        .disabled(disabled)
                } else {
                    Button(action: action) {
                        Image(systemName: "xmark.circle.fill")
                            .fontWeight(.bold)
                            .symbolRenderingMode(.palette)
                            .foregroundStyle(theme.accentColor.overlayColor, theme.accentColor)
                            .opacity(disabled ? 0.75 : 1)
                    }
                    .disabled(disabled)
                }
            }
        }
    }
}

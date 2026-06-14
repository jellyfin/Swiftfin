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

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled

    let disabled: Bool
    let action: () -> Void

    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItemGroup(placement: .topBarLeading) {
                Button {
                    action()
                } label: {
                    Image(systemName: isLiquidGlassEnabled ? "xmark" : "xmark.circle.fill")
                        .fontWeight(isLiquidGlassEnabled ? .regular : .bold)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(accentColor.overlayColor, accentColor)
                        .opacity(disabled ? 0.75 : 1)
                }
                .disabled(disabled)
            }
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ButtonStyle where Self == ToolbarPillButtonStyle {

    static var toolbarPill: ToolbarPillButtonStyle {
        ToolbarPillButtonStyle()
    }
}

struct ToolbarPillButtonStyle: ButtonStyle {

    @Default(.accentColor)
    private var accentColor

    @Environment(\.isEnabled)
    private var isEnabled

    private var foregroundStyle: some ShapeStyle {
        if isEnabled {
            accentColor.overlayColor
        } else {
            Color.secondary.overlayColor
        }
    }

    private var background: some ShapeStyle {
        if isEnabled {
            accentColor
        } else {
            Color.secondary
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(foregroundStyle)
            .font(.headline)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(background)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(isEnabled && !configuration.isPressed ? 1 : 0.5)
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// MARK: - TintedMaterialButtonStyle

extension ButtonStyle where Self == TintedMaterialButtonStyle {

    static var material: TintedMaterialButtonStyle {
        TintedMaterialButtonStyle(tint: Color.clear, foregroundColor: Color.primary)
    }

    static func tintedMaterial(tint: Color, foregroundColor: Color) -> TintedMaterialButtonStyle {
        TintedMaterialButtonStyle(
            tint: tint,
            foregroundColor: foregroundColor
        )
    }
}

struct TintedMaterialButtonStyle: ButtonStyle {

    @Environment(\.isSelected)
    private var isSelected
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isFocused)
    private var isFocused

    // Take tint instead of reading from view as
    // global accent color causes flashes of color
    let tint: Color
    let foregroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            TintedMaterial(tint: buttonTint)
                .id(isSelected)

            configuration.label
                .foregroundStyle(foregroundStyle)
                .symbolRenderingMode(.monochrome)
        }
        .hoverEffect(.lift)
    }

    private var buttonTint: Color {
        if isEnabled && isSelected {
            tint
        } else {
            Color.gray.opacity(0.3)
        }
    }

    private var foregroundStyle: AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(foregroundColor)
        } else if isEnabled {
            AnyShapeStyle(HierarchicalShapeStyle.primary)
        } else {
            AnyShapeStyle(Color.gray.opacity(0.3))
        }
    }
}

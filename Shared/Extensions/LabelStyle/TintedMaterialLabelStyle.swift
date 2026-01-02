//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: on tvOS focus, find way to disable brightness effect

extension LabelStyle where Self == TintedMaterialLabelStyle {

    static func tintedMaterial(tint: Color, foregroundColor: Color) -> TintedMaterialLabelStyle {
        TintedMaterialLabelStyle(
            tint: tint,
            foregroundColor: foregroundColor
        )
    }
}

struct TintedMaterialLabelStyle: LabelStyle {

    @Environment(\.isSelected)
    private var isSelected
    @Environment(\.isEnabled)
    private var isEnabled

    // Take tint instead of reading from view as
    // global accent color causes flashes of color
    let tint: Color
    let foregroundColor: Color

    private var buttonTint: Color {
        if isEnabled && isSelected {
            tint
        } else {
            // TODO: change to a full-opacity color
            Color.gray.opacity(0.3)
        }
    }

    private var foregroundStyle: AnyShapeStyle {
        if isSelected {
            AnyShapeStyle(foregroundColor)
        } else if isEnabled {
            AnyShapeStyle(HierarchicalShapeStyle.primary)
        } else {
            // TODO: change to a full-opacity color
            AnyShapeStyle(Color.gray.opacity(0.3))
        }
    }

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            TintedMaterial(tint: buttonTint)
                .id(isSelected)
            #if !os(tvOS)
                .cornerRadius(10)
            #endif

            Label(configuration)
                .foregroundStyle(foregroundStyle)
                .symbolRenderingMode(.monochrome)
        }
    }
}

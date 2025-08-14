//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

extension ButtonStyle where Self == ToolbarPillButtonStyle {

    static var toolbarPill: ToolbarPillButtonStyle {
        ToolbarPillButtonStyle(primary: Defaults[.accentColor], secondary: .secondary)
    }

    static func toolbarPill(_ primary: Color, _ secondary: Color = Color.secondary) -> ToolbarPillButtonStyle {
        ToolbarPillButtonStyle(primary: primary, secondary: secondary)
    }
}

// TODO: don't take `Color`, take generic `ShapeStyle`
struct ToolbarPillButtonStyle: ButtonStyle {

    @Environment(\.isEnabled)
    private var isEnabled

    let primary: Color
    let secondary: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(isEnabled ? primary.overlayColor : secondary)
            .font(.headline)
            .padding(.vertical, 5)
            .padding(.horizontal, 10)
            .background(isEnabled ? primary : secondary)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .opacity(isEnabled && !configuration.isPressed ? 1 : 0.5)
    }
}

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

    // Take tint instead of reading from view as
    // global accent color causes flashes of color
    let tint: Color
    let foregroundColor: Color

    func makeBody(configuration: Configuration) -> some View {
        ZStack {
            // TODO: use container relative shape instead of corner radius
            TintedMaterial(tint: buttonTint)
                .cornerRadius(10)
                .id(isSelected)

            configuration.label
                .foregroundStyle(foregroundStyle)
                .symbolRenderingMode(.monochrome)
        }
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

extension ButtonStyle where Self == IsPressedButtonStyle {

    static func isPressed(_ isPressed: @escaping (Bool) -> Void) -> IsPressedButtonStyle {
        IsPressedButtonStyle(isPressed: isPressed)
    }
}

struct IsPressedButtonStyle: ButtonStyle {

    let isPressed: (Bool) -> Void

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .onChange(of: configuration.isPressed, perform: isPressed)
    }
}

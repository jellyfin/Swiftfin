//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: on tvOS focus, find way to disable brightness effect

extension ButtonStyle where Self == TintedMaterialButtonStyle {

    // TODO: just be `Material` backed instead of `TintedMaterial`
    static var material: TintedMaterialButtonStyle {
        TintedMaterialButtonStyle(tint: Color.clear, foregroundColor: Color.primary)
    }

    static func material(focusScale: CGFloat) -> TintedMaterialButtonStyle {
        TintedMaterialButtonStyle(tint: Color.clear, foregroundColor: Color.primary, focusScale: focusScale)
    }

    static func tintedMaterial(tint: Color, foregroundColor: Color) -> TintedMaterialButtonStyle {
        TintedMaterialButtonStyle(
            tint: tint,
            foregroundColor: foregroundColor
        )
    }

    static func tintedMaterial(tint: Color, foregroundColor: Color, focusScale: CGFloat) -> TintedMaterialButtonStyle {
        TintedMaterialButtonStyle(
            tint: tint,
            foregroundColor: foregroundColor,
            focusScale: focusScale
        )
    }
}

struct TintedMaterialButtonStyle: ButtonStyle {

    // Take tint instead of reading from view as
    // global accent color causes flashes of color
    let tint: Color
    let foregroundColor: Color

    /// When set, the button grows to this scale on focus instead of the default
    /// `.hoverEffect(.lift)`. Use a value just above 1 to make the focus growth subtle.
    var focusScale: CGFloat?

    func makeBody(configuration: Configuration) -> some View {
        ButtonContent(
            configuration: configuration,
            tint: tint,
            foregroundColor: foregroundColor,
            focusScale: focusScale
        )
    }

    private struct ButtonContent: View {

        @Environment(\.isSelected)
        private var isSelected
        @Environment(\.isEnabled)
        private var isEnabled
        @Environment(\.isFocused)
        private var isFocused

        let configuration: ButtonStyleConfiguration
        let tint: Color
        let foregroundColor: Color
        let focusScale: CGFloat?

        // Rounds the material on both platforms. On tvOS the rounding used to come from
        // `.hoverEffect(.lift)`, so clip explicitly here — otherwise the smaller-growth
        // (focusScale) buttons would render with square corners.
        private var cornerRadius: CGFloat {
            #if os(tvOS)
            16
            #else
            10
            #endif
        }

        var body: some View {
            ZStack {
                TintedMaterial(tint: buttonTint)
                    .id(isSelected)

                configuration.label
                    .foregroundStyle(foregroundStyle)
                    .symbolRenderingMode(.monochrome)
            }
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .modifier(FocusGrowth(focusScale: focusScale, isFocused: isFocused))
        }

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
    }

    /// Applies the default lift hover effect, or — when a `focusScale` is provided — a
    /// smaller manual scale on focus so the button grows less.
    private struct FocusGrowth: ViewModifier {

        let focusScale: CGFloat?
        let isFocused: Bool

        @ViewBuilder
        func body(content: Content) -> some View {
            if let focusScale {
                content
                    .scaleEffect(isFocused ? focusScale : 1)
                    .animation(.easeOut(duration: 0.15), value: isFocused)
            } else {
                content
                    .hoverEffect(.lift)
            }
        }
    }
}

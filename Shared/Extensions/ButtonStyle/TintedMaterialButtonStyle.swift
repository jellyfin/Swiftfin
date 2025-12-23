//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension PrimitiveButtonStyle where Self == TintedMaterialButtonStyle {

    // TODO: just be `Material` backed instead of `TintedMaterial`
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

struct TintedMaterialButtonStyle: PrimitiveButtonStyle {

    @Environment(\.isSelected)
    private var isSelected
    @Environment(\.isEnabled)
    private var isEnabled

    #if os(tvOS)
    @FocusState
    private var isFocused: Bool
    #endif

    // Take tint instead of reading from view as
    // global accent color causes flashes of color
    let tint: Color
    let foregroundColor: Color

    @ViewBuilder
    private func contentView(configuration: Configuration) -> some View {
        ZStack {
            TintedMaterial(tint: buttonTint)
                .id(isSelected)
            #if !os(tvOS)
                .cornerRadius(10)
            #endif

            configuration.label
                .foregroundStyle(foregroundStyle)
                .symbolRenderingMode(.monochrome)
        }
        #if os(tvOS)
        .focusEffectDisabled()
        .scaleEffect(isFocused ? 1.05 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isFocused)
        #else
        .hoverEffect(.lift)
        #endif
    }

    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.trigger()
        } label: {
            contentView(configuration: configuration)
        }
        .buttonStyle(.plain)
        #if os(tvOS)
            .focused($isFocused)
        #endif
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

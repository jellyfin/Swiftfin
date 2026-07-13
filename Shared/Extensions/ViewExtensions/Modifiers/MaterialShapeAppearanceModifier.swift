//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct MaterialShapeAppearanceModifier<BackgroundShape: Shape>: ViewModifier {

    private struct SelectionAppearance {

        let tint: Color
        let foregroundColor: Color
    }

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    let shape: BackgroundShape
    let tint: Color?
    let isVisible: Bool
    private let selectionAppearance: SelectionAppearance?

    init(
        shape: BackgroundShape,
        tint: Color?,
        isVisible: Bool = true
    ) {
        self.shape = shape
        self.tint = tint
        self.isVisible = isVisible
        self.selectionAppearance = nil
    }

    init(
        shape: BackgroundShape,
        selectedTint: Color,
        selectedForegroundColor: Color
    ) {
        self.shape = shape
        self.tint = nil
        self.isVisible = true
        self.selectionAppearance = SelectionAppearance(
            tint: selectedTint,
            foregroundColor: selectedForegroundColor
        )
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if selectionAppearance != nil {
            appearanceBody(
                content
                    .foregroundStyle(resolvedForegroundStyle)
                    .symbolRenderingMode(.monochrome)
            )
        } else {
            appearanceBody(content)
        }
    }

    @ViewBuilder
    private func appearanceBody(_ content: some View) -> some View {
        #if os(tvOS)
        if #available(tvOS 26.0, *), isLiquidGlassEnabled {
            glassBody(content)
        } else {
            legacyBody(content)
        }
        #else
        if #available(iOS 26.0, *), isLiquidGlassEnabled {
            glassBody(content)
        } else {
            legacyBody(content)
        }
        #endif
    }

    private var resolvedTint: Color? {
        guard let selectionAppearance else { return tint }

        if isEnabled && isSelected {
            return selectionAppearance.tint
        } else {
            return Color.gray.opacity(0.3)
        }
    }

    private var resolvedForegroundStyle: AnyShapeStyle {
        guard let selectionAppearance else {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }

        if isSelected {
            return AnyShapeStyle(selectionAppearance.foregroundColor)
        } else if isEnabled {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        } else {
            return AnyShapeStyle(Color.gray.opacity(0.3))
        }
    }

    @ViewBuilder
    private var legacyBackground: some View {
        if isVisible {
            if let resolvedTint {
                if selectionAppearance != nil {
                    tintedLegacyMaterial(resolvedTint.opacity(0.75))
                        .transition(.opacity)
                } else {
                    shape
                        .fill(resolvedTint)
                        .transition(.opacity)
                }
            } else {
                #if os(tvOS)
                tintedLegacyMaterial(.white.opacity(0.2))
                    .transition(.opacity)
                #else
                shape
                    .fill(.ultraThinMaterial)
                    .transition(.opacity)
                #endif
            }
        }
    }

    private func tintedLegacyMaterial(_ tint: Color) -> some View {
        shape
            .fill(Material.ultraThinMaterial)
            .background {
                shape.fill(tint)
            }
    }

    private func legacyBody(_ content: some View) -> some View {
        content
            .background {
                legacyBackground
            }
            .overlay {
                if isVisible {
                    shape
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                        .transition(.opacity)
                }
            }
            .clipShape(shape)
            .contentShape(shape)
    }

    @available(iOS 26.0, tvOS 26.0, *)
    private func glassBody(_ content: some View) -> some View {
        content
            .glassEffect(
                isVisible ? .regular
                    .tint(resolvedTint)
                    .interactive() : .identity,
                in: shape
            )
            .overlay {
                if isVisible {
                    shape
                        .stroke(.white.opacity(0.1), lineWidth: 1)
                        .transition(.opacity)
                }
            }
            .contentShape(shape)
    }
}

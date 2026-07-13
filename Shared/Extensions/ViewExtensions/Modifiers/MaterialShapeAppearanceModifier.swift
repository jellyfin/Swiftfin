//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct MaterialShapeAppearance {

    fileprivate struct SelectionAppearance {

        let foregroundColor: Color
    }

    /// The standard material appearance.
    static let regular = MaterialShapeAppearance(isVisible: true)

    /// An appearance that does not draw material or a border.
    static let identity = MaterialShapeAppearance(isVisible: false)

    fileprivate var tint: Color?
    fileprivate var isVisible: Bool
    fileprivate var selectionAppearance: SelectionAppearance?

    private init(isVisible: Bool) {
        self.tint = nil
        self.isVisible = isVisible
        self.selectionAppearance = nil
    }

    func tint(_ tint: Color?) -> Self {
        var copy = self
        copy.tint = tint
        copy.selectionAppearance = nil
        return copy
    }

    /// Resolves the tint and foreground color from the selected and enabled environment values.
    func selection(
        tint: Color,
        foregroundColor: Color
    ) -> Self {
        var copy = self
        copy.tint = tint
        copy.selectionAppearance = SelectionAppearance(
            foregroundColor: foregroundColor
        )
        return copy
    }
}

extension View {

    /// Applies a material appearance in the given shape, using liquid glass when enabled and available.
    func materialShapeAppearance(
        _ appearance: MaterialShapeAppearance = .regular,
        in shape: some Shape
    ) -> some View {
        modifier(
            MaterialShapeAppearanceModifier(
                appearance: appearance,
                shape: shape
            )
        )
    }
}

private struct MaterialShapeAppearanceModifier<BackgroundShape: Shape>: ViewModifier {

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled
    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    let appearance: MaterialShapeAppearance
    let shape: BackgroundShape

    private var isPositiveSelectionState: Bool {
        isEnabled && isSelected
    }

    private var subduedColor: Color {
        Color.gray.opacity(0.3)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if appearance.selectionAppearance != nil {
            appearanceBody(
                content
                    .foregroundStyle(resolvedForegroundStyle)
                    .symbolRenderingMode(.monochrome)
            )
        } else {
            appearanceBody(content)
        }
    }

    private func appearanceBody(_ content: some View) -> some View {
        platformAppearanceBody(content)
            .overlay {
                appearanceBorder
            }
            .contentShape(shape)
    }

    @ViewBuilder
    private func platformAppearanceBody(_ content: some View) -> some View {
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
        guard appearance.selectionAppearance != nil else {
            return appearance.tint
        }

        return isPositiveSelectionState ? appearance.tint : subduedColor
    }

    private var resolvedForegroundStyle: AnyShapeStyle {
        guard let selectionAppearance = appearance.selectionAppearance else {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }

        if isPositiveSelectionState {
            return AnyShapeStyle(selectionAppearance.foregroundColor)
        } else if isEnabled {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        } else {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }
    }

    @ViewBuilder
    private var legacyBackground: some View {
        if appearance.isVisible {
            if let resolvedTint {
                if appearance.selectionAppearance != nil {
                    tintedLegacyMaterial(resolvedTint)
                } else {
                    shape
                        .fill(resolvedTint)
                }
            } else {
                #if os(tvOS)
                tintedLegacyMaterial(.white.opacity(0.2))
                #else
                shape
                    .fill(.ultraThinMaterial)
                #endif
            }
        }
    }

    @ViewBuilder
    private var appearanceBorder: some View {
        if appearance.isVisible {
            shape
                .stroke(.white.opacity(0.1), lineWidth: 1)
                .transition(.opacity)
        }
    }

    private func tintedLegacyMaterial(_ tint: Color) -> some View {
        shape
//            .fill(Material.ultraThinMaterial)
                .background {
                    shape.fill(tint)
                }
    }

    private func legacyBody(_ content: some View) -> some View {
        content
            .background {
                legacyBackground
                    .transition(.opacity)
            }
            .clipShape(shape)
    }

    @available(iOS 26.0, tvOS 26.0, *)
    private func glassBody(_ content: some View) -> some View {
        content
            .glassEffect(
                appearance.isVisible ? .regular
                    .tint(resolvedTint)
                    .interactive() : .identity,
                in: shape
            )
    }
}

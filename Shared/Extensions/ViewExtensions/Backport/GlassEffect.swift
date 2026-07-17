//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct BackportGlass {

    fileprivate struct SelectionAppearance {

        let foregroundColor: Color
    }

    /// The standard glass appearance.
    static let regular = BackportGlass(isVisible: true)

    /// An appearance that does not draw glass or a border.
    static let identity = BackportGlass(isVisible: false)

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

    /// Configures the tint and foreground color for the selected and enabled state.
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

struct BackportGlassEffectModifier<BackgroundShape: Shape>: ViewModifier {

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled

    @Environment(\.isEnabled)
    private var isEnabled
    @Environment(\.isSelected)
    private var isSelected

    let glass: BackportGlass
    let shape: BackgroundShape

    private var isPositiveSelectionState: Bool {
        isEnabled && isSelected
    }

    private var subduedColor: Color {
        Color.gray.opacity(0.3)
    }

    @ViewBuilder
    func body(content: Content) -> some View {
        if glass.selectionAppearance != nil {
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
        guard glass.selectionAppearance != nil else {
            return glass.tint
        }

        return isPositiveSelectionState ? glass.tint : subduedColor
    }

    private var resolvedForegroundStyle: AnyShapeStyle {
        guard isPositiveSelectionState,
              let selectionAppearance = glass.selectionAppearance
        else {
            return AnyShapeStyle(HierarchicalShapeStyle.primary)
        }

        return AnyShapeStyle(selectionAppearance.foregroundColor)
    }

    @ViewBuilder
    private var legacyBackground: some View {
        if glass.isVisible {
            if let resolvedTint {
                shape
                    .fill(resolvedTint)
            } else {
                #if os(tvOS)
                shape
                    .fill(Material.ultraThinMaterial)
                    .background {
                        shape.fill(.white.opacity(0.2))
                    }
                #else
                shape
                    .fill(.ultraThinMaterial)
                #endif
            }
        }
    }

    @ViewBuilder
    private var appearanceBorder: some View {
        if glass.isVisible {
            shape
                .stroke(.white.opacity(0.1), lineWidth: 1)
                .transition(.opacity)
        }
    }

    private func legacyBody(_ content: some View) -> some View {
        content
            .background {
                legacyBackground
                    .transition(.opacity)
            }
            .clipShape(shape)
            .overlay {
                appearanceBorder
            }
            .subtleShadow()
    }

    @available(iOS 26.0, tvOS 26.0, *)
    private func glassBody(_ content: some View) -> some View {
        content
            .glassEffect(
                glass.isVisible ? .regular
                    .tint(resolvedTint)
                    .interactive() : .identity,
                in: shape
            )
    }
}

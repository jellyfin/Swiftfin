//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import SwiftUI

struct CapsuleLabelStyle: LabelStyle {

    @Default(.isLiquidGlassEnabled)
    private var isLiquidGlassEnabled

    private let _insets: EdgeInsets
    private let spacing: CGFloat
    private let tint: Color?
    private let isTitleVisible: Bool
    private let isIconTrailing: Bool

    private var insets: EdgeInsets {
        #if os(tvOS)
        .init(vertical: 8, horizontal: 16)
        #else
        .init(vertical: 5, horizontal: 10)
        #endif
    }

    init(
        insets: EdgeInsets,
        spacing: CGFloat = 4,
        tint: Color? = nil,
        isTitleVisible: Bool = true,
        isIconTrailing: Bool = false
    ) {
        self._insets = insets
        self.spacing = spacing
        self.tint = tint
        self.isTitleVisible = isTitleVisible
        self.isIconTrailing = isIconTrailing
    }

    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            if !isIconTrailing {
                configuration.icon
            }

            if isTitleVisible {
                configuration.title
            }

            if isIconTrailing {
                configuration.icon
            }
        }
        .padding(insets)
        .modifier(
            CapsuleLabelAppearanceModifier(
                isLiquidGlassEnabled: isLiquidGlassEnabled,
                tint: tint
            )
        )
    }
}

private struct CapsuleLabelAppearanceModifier: ViewModifier {

    let isLiquidGlassEnabled: Bool
    let tint: Color?

    func body(content: Content) -> some View {
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

    @ViewBuilder
    private func legacyBody(_ content: Content) -> some View {
        content
            .background {
                if let tint {
                    Capsule()
                        .fill(tint)
                } else {
                    #if os(tvOS)
                    Capsule()
                        .fill(Material.ultraThinMaterial.tinted(.white.opacity(0.2)))
                    #else
                    Capsule()
                        .fill(.ultraThinMaterial)
                    #endif
                }
            }
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
            .clipShape(.capsule)
            .contentShape(.capsule)
    }

    @available(iOS 26.0, tvOS 26.0, *)
    private func glassBody(_ content: Content) -> some View {
        content
            .glassEffect(
                .regular
                    .tint(tint)
                    .interactive(),
                in: Capsule()
            )
            .overlay {
                Capsule()
                    .stroke(.white.opacity(0.1), lineWidth: 1)
            }
            .contentShape(.capsule)
    }
}

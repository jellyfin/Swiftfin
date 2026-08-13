//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct Backport<Content> {

    let content: Content
}

extension Backport where Content: View {

    @ViewBuilder
    func buttonStyle(
        _ style: some BackportButtonStyle
    ) -> some View {
        content.buttonStyle(
            BackportPrimitiveButtonStyle(style: style)
        )
    }

    @ViewBuilder
    func glassEffect(
        _ glass: BackportGlass = .regular,
        in shape: some Shape
    ) -> some View {
        content.modifier(
            BackportGlassEffectModifier(
                glass: glass,
                shape: shape
            )
        )
    }

    @ViewBuilder
    func scrollEdgeEffectStyle(
        _ style: ScrollEdgeEffectStyle?,
        for edges: Edge.Set
    ) -> some View {
        if #available(iOS 26.0, *) {
            content.scrollEdgeEffectStyle(
                style?.swiftUIValue,
                for: edges
            )
        } else {
            content
        }
    }
}

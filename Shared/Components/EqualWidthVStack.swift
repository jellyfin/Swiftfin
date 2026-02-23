//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: use Group(subviews:) when available

struct EqualWidthVStack<Content: View>: View {

    @State
    private var maxChildWidth: CGFloat?

    private let alignment: HorizontalAlignment
    private let content: Content
    private let spacing: CGFloat?

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
        self.spacing = spacing
    }

    var body: some View {
        _VariadicView.Tree(
            EqualWidthVStackRoot(
                alignment: alignment,
                spacing: spacing,
                maxChildWidth: $maxChildWidth
            )
        ) {
            content
        }
    }
}

private struct EqualWidthVStackRoot: _VariadicView_UnaryViewRoot {

    let alignment: HorizontalAlignment
    let spacing: CGFloat?
    let maxChildWidth: Binding<CGFloat?>

    private var childFrameAlignment: Alignment {
        switch alignment {
        case .leading:
            .leading
        case .trailing:
            .trailing
        default:
            .center
        }
    }

    func body(children: _VariadicView.Children) -> some View {
        VStack(alignment: alignment, spacing: spacing) {
            ForEach(children) { child in
                child
                    .onSizeChanged { size, _ in
                        maxChildWidth.wrappedValue = max(maxChildWidth.wrappedValue ?? 0, size.width)
                    }
                    .frame(width: maxChildWidth.wrappedValue, alignment: childFrameAlignment)
                    .focusSection()
            }
        }
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

@ViewBuilder
func HStack(
    reversed: Bool,
    alignment: VerticalAlignment = .center,
    spacing: CGFloat? = nil,
    @ViewBuilder content: @escaping () -> some View
) -> some View {
    ReversibleHStack(
        isReversed: reversed,
        alignment: alignment,
        spacing: spacing,
        content: content
    )
}

private struct ReversibleHStack<Content: View>: View {

    private let isReversed: Bool
    private let alignment: VerticalAlignment
    private let content: Content
    private let spacing: CGFloat?

    init(
        isReversed: Bool,
        alignment: VerticalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.isReversed = isReversed
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

    var body: some View {
        _VariadicView.Tree(
            ReversibleHStackLayout(
                isReversed: isReversed,
                alignment: alignment,
                spacing: spacing
            )
        ) {
            content
        }
    }

    struct ReversibleHStackLayout: _VariadicView_UnaryViewRoot {

        let isReversed: Bool
        let alignment: VerticalAlignment
        let spacing: CGFloat?

        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {
            HStack(alignment: alignment, spacing: spacing) {
                if isReversed {
                    ForEach(children.reversed()) { child in
                        child
                    }
                } else {
                    children
                }
            }
        }
    }
}

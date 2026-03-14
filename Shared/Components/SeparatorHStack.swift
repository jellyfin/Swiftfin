//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// https://movingparts.io/variadic-views-in-swiftui

/// An `HStack` that inserts an optional `separator` between views.
///
/// - Note: Default spacing is removed. The separator view is responsible
///         for spacing.
struct SeparatorHStack<Content: View, Separator: View>: View {

    private var content: Content
    private var separator: Separator

    var body: some View {
        _VariadicView.Tree(
            SeparatorHStackLayout(
                separator: separator
            )
        ) {
            content
        }
    }
}

extension SeparatorHStack where Separator == RowDivider {

    init(
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            content: content(),
            separator: RowDivider()
        )
    }
}

extension SeparatorHStack {

    init(
        @ViewBuilder separator: @escaping () -> Separator,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            content: content(),
            separator: separator()
        )
    }
}

extension SeparatorHStack {

    struct SeparatorHStackLayout: _VariadicView_UnaryViewRoot {

        var separator: Separator

        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {

            let last = children.last?.id

            localHStack {
                ForEach(children) { child in
                    child

                    if child.id != last {
                        separator
                    }
                }
            }
        }

        @ViewBuilder
        private func localHStack(@ViewBuilder content: @escaping () -> some View) -> some View {
            HStack(spacing: 0) {
                content()
            }
        }
    }
}

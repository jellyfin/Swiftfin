//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// https://movingparts.io/variadic-views-in-swiftui

/// A `VStack` that inserts an optional `separator` between views.
///
/// - Note: Default spacing is removed. The separator view is responsible
///         for spacing.
struct SeparatorVStack<Content: View, Separator: View>: View {

    private let alignment: HorizontalAlignment
    private let content: Content
    private let separator: Separator

    var body: some View {
        _VariadicView.Tree(
            SeparatorVStackLayout(
                alignment: alignment,
                separator: separator
            )
        ) {
            content
        }
    }
}

extension SeparatorVStack {

    init(
        alignment: HorizontalAlignment = .center,
        @ViewBuilder separator: @escaping () -> Separator,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.init(
            alignment: alignment,
            content: content(),
            separator: separator()
        )
    }
}

extension SeparatorVStack {

    struct SeparatorVStackLayout: _VariadicView_UnaryViewRoot {

        let alignment: HorizontalAlignment
        let separator: Separator

        @ViewBuilder
        func body(children: _VariadicView.Children) -> some View {

            let last = children.last?.id

            VStack(alignment: alignment, spacing: 0) {
                ForEach(children) { child in
                    child

                    if child.id != last {
                        separator
                    }
                }
            }
        }
    }
}

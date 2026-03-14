//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A view that takes a view to affect layout while overlaying the content.
struct AlternateLayoutView<Content: View, Layout: View>: View {

    @State
    private var layoutSize: CGSize = .zero

    private let alignment: Alignment
    private let content: (CGSize) -> Content
    private let layout: Layout

    private let passLayoutSize: Bool

    init(
        alignment: Alignment = .center,
        @ViewBuilder layout: @escaping () -> Layout,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.content = { _ in content() }
        self.layout = layout()

        self.passLayoutSize = false
    }

    init(
        alignment: Alignment = .center,
        @ViewBuilder layout: @escaping () -> Layout,
        @ViewBuilder content: @escaping (CGSize) -> Content
    ) {
        self.alignment = alignment
        self.content = content
        self.layout = layout()

        self.passLayoutSize = true
    }

    var body: some View {
        layout
            .hidden()
            .trackingSize($layoutSize)
            .overlay(alignment: alignment) {
                if passLayoutSize {
                    content(layoutSize)
                } else {
                    content(.zero)
                }
            }
    }
}

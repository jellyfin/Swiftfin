//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A view that takes a view to affect layout while overlaying the content.
struct AlternateLayoutView<Content: View, Layout: View>: View {

    private let alignment: Alignment
    private let content: () -> Content
    private let layout: () -> Layout

    init(
        alignment: Alignment = .center,
        @ViewBuilder layout: @escaping () -> Layout,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.alignment = alignment
        self.content = content
        self.layout = layout
    }

    var body: some View {
        layout()
            .hidden()
            .overlay(alignment: alignment) {
                content()
            }
    }
}

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
    private var layoutSize: FrameAndSafeAreaInsets = .zero

    private let alignment: Alignment
    private let content: (FrameAndSafeAreaInsets) -> Content
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
        self.content = { frame in content(frame.frame.size) }
        self.layout = layout()

        self.passLayoutSize = true
    }

    init(
        alignment: Alignment = .center,
        @ViewBuilder layout: @escaping () -> Layout,
        @ViewBuilder content: @escaping (FrameAndSafeAreaInsets) -> Content
    ) {
        self.alignment = alignment
        self.content = content
        self.layout = layout()

        self.passLayoutSize = true
    }

    var body: some View {
        layout
            .hidden()
            .if(passLayoutSize) { view in
                view.onSizeChanged {
                    layoutSize = .init(
                        frame: .init(
                            origin: .zero,
                            size: $0
                        ),
                        safeAreaInsets: $1
                    )
                }
            }
            .overlay(alignment: alignment) {
                content(layoutSize)
            }
    }
}

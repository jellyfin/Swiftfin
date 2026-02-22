//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct EqualWidthVStack<Content: View>: View {

    @State
    private var maxChildWidth: CGFloat?

    private let alignment: HorizontalAlignment
    private let spacing: CGFloat?
    private let content: Content

    init(
        alignment: HorizontalAlignment = .center,
        spacing: CGFloat? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.spacing = spacing
        self.content = content()
    }

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

    var body: some View {
        Group(subviews: content) { subviews in
            VStack(alignment: alignment, spacing: spacing) {
                ForEach(subviews) { subview in
                    subview
                        .onSizeChanged { size, _ in
                            maxChildWidth = max(maxChildWidth ?? 0, size.width)
                        }
                        .frame(width: maxChildWidth, alignment: childFrameAlignment)
                        .focusSection()
                }
            }
        }
    }
}

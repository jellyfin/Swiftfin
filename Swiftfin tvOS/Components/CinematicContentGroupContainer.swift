//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct CinematicContentGroupContainer<Content: View>: View {

    @Environment(\.frameForParentView)
    private var frameForParentView

    private let alignment: Alignment
    private let content: Content

    init(
        alignment: Alignment = .bottomLeading,
        @ViewBuilder content: () -> Content
    ) {
        self.alignment = alignment
        self.content = content()
    }

    private var resolvedHeight: CGFloat {
        let parentHeight = frameForParentView[.scrollView, default: .zero].frame.height

        return max(parentHeight - 75, 0)
    }

    var body: some View {
        content
            .frame(height: resolvedHeight, alignment: alignment)
            .frame(maxWidth: .infinity)
    }
}

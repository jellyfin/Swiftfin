//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct DotHStack<Content: View>: View {

    @AdaptiveLayout
    private var viewLayout

    private let padding: CGFloat?
    private let content: Content

    init(padding: CGFloat? = nil, @ViewBuilder content: () -> Content) {
        self.padding = padding
        self.content = content()
    }

    var body: some View {
        let dotSize: CGFloat = viewLayout.value(standard: 2, large: 5)
        SeparatorHStack {
            Circle()
                .frame(width: dotSize, height: dotSize)
                .padding(.horizontal, padding ?? viewLayout.value(standard: 5, large: 10))
        } content: {
            content
        }
    }
}

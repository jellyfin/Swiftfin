//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ScrollIfLargerThanContainerModifier: ViewModifier {

    @State
    private var contentSize: CGSize = .zero
    @State
    private var layoutSize: CGSize = .zero

    let axes: Axis.Set
    let padding: CGFloat

    private var isVerticallyLarger: Bool {
        contentSize.height >= layoutSize.height
    }

    private var isHorizontallyLarger: Bool {
        contentSize.width >= layoutSize.width
    }

    func body(content: Content) -> some View {
        AlternateLayoutView {
            Color.clear
                .trackingSize($layoutSize)
        } content: {
            ScrollView(axes) {
                content
                    .trackingSize($contentSize)
            }
            .frame(
                maxWidth: axes.contains(.horizontal) ? (isHorizontallyLarger ? .infinity : contentSize.width) : nil,
                maxHeight: axes.contains(.vertical) ? (isVerticallyLarger ? .infinity : contentSize.height) : nil
            )
            .backport // iOS 17
            .scrollClipDisabled()
            .scrollDisabled(!(axes.contains(.vertical) && isVerticallyLarger) || (axes.contains(.horizontal) && isHorizontallyLarger))
            .scrollIndicators(.never)
        }
    }
}

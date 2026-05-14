//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ScrollIfLargerThanContainerModifier: ViewModifier {

    @ViewContextContains(.withConstrainedSize)
    private var withConstrainedSize: Bool

    @State
    private var contentFrame: CGRect = .zero

    let axes: Axis.Set
    let padding: CGFloat
    let alignment: Alignment

    func body(content: Content) -> some View {
        AlternateLayoutView(alignment: alignment) {
            Color.clear
        } content: { layoutSize in

            let isHorizontallyLarger: Bool = (contentFrame.width + padding >= layoutSize.width) && axes.contains(.horizontal)
            let isVerticallyLarger: Bool = (contentFrame.height + padding >= layoutSize.height) && axes.contains(.vertical)

            ScrollView(axes) {
                content
                    .trackingFrame($contentFrame)
            }
            .frame(
                maxWidth: axes.contains(.horizontal) ? (isHorizontallyLarger ? .infinity : contentFrame.width) : nil,
                maxHeight: axes.contains(.vertical) ? (isVerticallyLarger ? .infinity : contentFrame.height) : nil,
                alignment: alignment
            )
            .backport // iOS 17
            .scrollClipDisabled()
            .scrollDisabled((axes.contains(.horizontal) && !isHorizontallyLarger) || (axes.contains(.vertical) && !isVerticallyLarger))
            .scrollIndicators(.never)
        }
        .if(withConstrainedSize) { view in
            view.frame(maxWidth: contentFrame.width)
        }
    }
}

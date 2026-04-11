//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BackgroundParallaxHeaderModifier<Header: View>: ViewModifier {

    @Binding
    private var scrollViewOffset: CGFloat

    @State
    private var contentSize: CGSize = .zero

    private let height: CGFloat
    private let multiplier: CGFloat
    private let header: () -> Header

    init(
        _ scrollViewOffset: Binding<CGFloat>,
        height: CGFloat,
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> Header
    ) {
        self._scrollViewOffset = scrollViewOffset
        self.height = height
        self.multiplier = multiplier
        self.header = header
    }

    func body(content: Content) -> some View {
        content
            .trackingSize($contentSize)
            .background(alignment: .top) {
                header()
                    .offset(y: scrollViewOffset > 0 ? -scrollViewOffset * multiplier : 0)
                    .scaleEffect(scrollViewOffset < 0 ? (height - scrollViewOffset) / height : 1, anchor: .top)
                    .frame(width: contentSize.width)
                    .mask(alignment: .top) {
                        Color.black
                            .frame(height: max(0, height - scrollViewOffset))
                    }
                    .ignoresSafeArea()
            }
    }
}

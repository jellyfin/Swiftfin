//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ItemViewOffsetScrollView<Header: View, Overlay: View, Content: View>: View {

    @State
    private var scrollViewOffset: CGFloat = 0
    @State
    private var size: CGSize = .zero
    @State
    private var safeAreaInsets: EdgeInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)

    private let header: () -> Header
    private let overlay: () -> Overlay
    private let content: () -> Content
    private let heightRatio: CGFloat

    init(
        headerHeight: CGFloat = 0,
        @ViewBuilder header: @escaping () -> Header,
        @ViewBuilder overlay: @escaping () -> Overlay,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.header = header
        self.overlay = overlay
        self.content = content
        self.heightRatio = headerHeight
    }

    private var headerOpacity: CGFloat {
        let start = size.height * heightRatio - safeAreaInsets.top - 120
        let end = size.height * heightRatio - safeAreaInsets.top - 50
        let diff = end - start
        let opacity = clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
        return opacity
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                overlay()
                    .frame(height: (size.height + safeAreaInsets.vertical) * heightRatio)

                content()
            }
        }
        .edgesIgnoringSafeArea(.top)
        .onSizeChanged { size, safeAreaInsets in
            self.size = size
            self.safeAreaInsets = safeAreaInsets
        }
        .scrollViewOffset($scrollViewOffset)
        .navigationBarOffset(
            $scrollViewOffset,
            start: size.height * heightRatio - 50 - safeAreaInsets.top,
            end: size.height * heightRatio - safeAreaInsets.top
        )
        .backgroundParallaxHeader(
            $scrollViewOffset,
            height: (size.height + safeAreaInsets.vertical) * heightRatio,
            multiplier: 0.3
        ) {
            header()
                .frame(height: (size.height + safeAreaInsets.vertical) * heightRatio)
        }
    }
}

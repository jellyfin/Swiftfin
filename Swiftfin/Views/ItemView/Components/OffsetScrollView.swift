//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: given height or height ratio options

// The fading values just "feel right" and is the same for iOS and iPadOS.
// Adjust if necessary or if a more concrete design comes along.

extension ItemView {

    struct OffsetScrollView<Header: View, Overlay: View, Content: View>: View {

        @State
        private var scrollViewOffset: CGFloat = 0
        @State
        private var size: CGSize = .zero
        @State
        private var safeAreaInsets: EdgeInsets = .zero

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
            let start = (size.height + safeAreaInsets.vertical) * heightRatio - safeAreaInsets.top - 90
            let end = (size.height + safeAreaInsets.vertical) * heightRatio - safeAreaInsets.top - 40
            let diff = end - start
            let opacity = clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
            return opacity
        }

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    overlay()
                        .frame(height: (size.height + safeAreaInsets.vertical) * heightRatio)
                        .overlay {
                            Color.systemBackground
                                .opacity(headerOpacity)
                        }

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
                start: (size.height + safeAreaInsets.vertical) * heightRatio - safeAreaInsets.top - 45,
                end: (size.height + safeAreaInsets.vertical) * heightRatio - safeAreaInsets.top - 5
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
}

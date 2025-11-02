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

        private let header: Header
        private let overlay: Overlay
        private let content: Content
        private let heightRatio: CGFloat

        init(
            heightRatio: CGFloat = 0,
            @ViewBuilder header: @escaping () -> Header,
            @ViewBuilder overlay: @escaping () -> Overlay,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.header = header()
            self.overlay = overlay()
            self.content = content()
            self.heightRatio = clamp(heightRatio, min: 0, max: 1)
        }

        private var headerOpacity: CGFloat {
            let headerHeight = headerHeight
            let start = headerHeight - safeAreaInsets.top - 90
            let end = headerHeight - safeAreaInsets.top - 40
            let diff = end - start
            let opacity = clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
            return opacity
        }

        private var headerHeight: CGFloat {
            (size.height + safeAreaInsets.vertical) * heightRatio
        }

        var body: some View {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    AlternateLayoutView {
                        Color.clear
                            .frame(height: headerHeight, alignment: .bottom)
                    } content: {
                        overlay
                            .frame(height: headerHeight, alignment: .bottom)
                    }
                    .overlay {
                        Color.systemBackground
                            .opacity(headerOpacity)
                    }

                    content
                }
            }
            .edgesIgnoringSafeArea(.top)
            .trackingSize($size, $safeAreaInsets)
            .scrollViewOffset($scrollViewOffset)
            .navigationBarOffset(
                $scrollViewOffset,
                start: headerHeight - safeAreaInsets.top - 45,
                end: headerHeight - safeAreaInsets.top - 5
            )
            .backgroundParallaxHeader(
                $scrollViewOffset,
                height: headerHeight,
                multiplier: 0.3
            ) {
                header
                    .frame(height: headerHeight)
            }
        }
    }
}

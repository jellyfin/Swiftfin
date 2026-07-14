//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    @ViewBuilder
    func backgroundParallaxHeader(
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> some View
    ) -> some View {
        modifier(
            BackgroundParallaxHeaderModifier(
                multiplier: multiplier,
                header: header
            )
        )
    }
}

struct BackgroundParallaxHeaderModifier<Background: View>: ViewModifier {

    @Environment(\.frameForParentView)
    private var frameForParentView

    @State
    private var contentFrame: CGRect = .zero
    @State
    private var headerSize: CGSize = .zero

    private let background: Background
    private let multiplier: CGFloat

    init(
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> Background
    ) {
        self.background = header()
        self.multiplier = multiplier
    }

    private var scrollViewOffset: CGFloat {
        -contentFrame.minY
    }

    private var scrollViewSafeAreaInsets: EdgeInsets {
        frameForParentView[.scrollView, default: .zero].safeAreaInsets
    }

    private var maskHeight: CGFloat {
        max(0, contentFrame.height + scrollViewSafeAreaInsets.top - offset)
    }

    private var offset: CGFloat {
        let position = scrollViewOffset + frameForParentView[.navigationStack, default: .zero].safeAreaInsets.top

        return if scrollViewOffset < 0, abs(scrollViewOffset) >= scrollViewSafeAreaInsets.top {
            position
        } else {
            position - (abs(scrollViewOffset + scrollViewSafeAreaInsets.top) * multiplier)
        }
    }

    private var navigationBarHeight: CGFloat {
        abs(frameForParentView[.navigationStack, default: .zero].safeAreaInsets.top - scrollViewSafeAreaInsets.top)
    }

    private var adjustedHeaderHeight: CGFloat {
        headerSize.height + max(
            0, navigationBarHeight
        )
    }

    private var scaleEffect: CGFloat {
        guard headerSize.height > 0 else { return 1 }

        var scale: CGFloat {
            if scrollViewOffset < 0, abs(scrollViewOffset) >= scrollViewSafeAreaInsets.top {
                (adjustedHeaderHeight + abs(scrollViewOffset + scrollViewSafeAreaInsets.top)) / headerSize.height
            } else {
                adjustedHeaderHeight / headerSize.height
            }
        }

        return max(1, scale)
    }

    func body(content: Content) -> some View {
        content
            .trackingFrame($contentFrame)
            .background(alignment: .top) {
                background
                    .trackingSize($headerSize)
                    .scaleEffect(scaleEffect, anchor: .top)
                    .mask(alignment: .top) {
                        Color.black
                            .frame(height: maskHeight)
                            .offset(y: -scrollViewSafeAreaInsets.top)
                    }
                    .offset(y: offset)
            }
    }
}

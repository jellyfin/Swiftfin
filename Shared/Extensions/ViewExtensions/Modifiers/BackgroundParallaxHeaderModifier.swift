//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

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
    @Environment(\.layoutDirection)
    private var layoutDirection

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
        let scrollView = frameForParentView[.scrollView, default: .zero]
        return scrollView.frame.minY - scrollView.safeAreaInsets.top - contentFrame.minY
    }

    private var navigationFrame: CGRect {
        let navigation = frameForParentView[.navigationStack, default: .zero]
        let leftInset = layoutDirection == .leftToRight ? navigation.safeAreaInsets.leading : navigation.safeAreaInsets.trailing
        return CGRect(
            x: navigation.frame.minX - leftInset,
            y: navigation.frame.minY,
            width: navigation.sizeIncludingSafeArea.width,
            height: navigation.frame.height
        )
    }

    private var backgroundWidth: CGFloat? {
        navigationFrame.width > 0 ? navigationFrame.width : nil
    }

    private var horizontalOffset: CGFloat {
        guard navigationFrame.width > 0, contentFrame.width > 0 else { return 0 }

        return navigationFrame.midX - contentFrame.midX
    }

    private var scrollViewTopInset: CGFloat {
        frameForParentView[.scrollView, default: .zero].safeAreaInsets.top
    }

    private var navigationTopInset: CGFloat {
        frameForParentView[.navigationStack, default: .zero].safeAreaInsets.top
    }

    private var maskHeight: CGFloat {
        max(0, contentFrame.height + scrollViewTopInset - offset)
    }

    private var offset: CGFloat {
        scrollViewOffset + navigationTopInset - max(0, scrollViewOffset + scrollViewTopInset) * multiplier
    }

    private var scaleEffect: CGFloat {
        guard headerSize.height > 0 else { return 1 }

        let navigationBarHeight = max(0, scrollViewTopInset - navigationTopInset)
        let overscroll = max(0, -scrollViewOffset - scrollViewTopInset)
        return 1 + (navigationBarHeight + overscroll) / headerSize.height
    }

    func body(content: Content) -> some View {
        content
            .trackingFrame($contentFrame)
            .background(alignment: .top) {
                MirrorExtensionView(edges: .top) {
                    background
                        .frame(width: backgroundWidth)
                        .fixedSize(horizontal: false, vertical: true)
                        .trackingSize($headerSize)
                }
                .scaleEffect(scaleEffect, anchor: .top)
                .mask(alignment: .top) {
                    Color.black
                        .frame(height: maskHeight)
                        .offset(y: -scrollViewTopInset)
                }
                .offset(x: horizontalOffset, y: offset)
            }
    }
}

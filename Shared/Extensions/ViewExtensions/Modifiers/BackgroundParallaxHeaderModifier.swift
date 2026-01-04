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

    @State
    private var headerFrame: CGRect = .zero

    private let multiplier: CGFloat
    private let background: Background

    init(
        multiplier: CGFloat = 1,
        @ViewBuilder header: @escaping () -> Background
    ) {
        self.multiplier = multiplier
        self.background = header()
    }

    private var contentFrame: CGRect {
        frameForParentView[.scrollViewHeader, default: .zero].frame
    }

    private var scrollViewOffset: CGFloat {
        -frameForParentView[.scrollViewHeader, default: .zero].frame.minY
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
        headerFrame.height + max(
            0, navigationBarHeight
        )
    }

    private var scaleEffect: CGFloat {
        var t: CGFloat {
            if scrollViewOffset < 0, abs(scrollViewOffset) >= scrollViewSafeAreaInsets.top {
                return (adjustedHeaderHeight + abs(scrollViewOffset + scrollViewSafeAreaInsets.top)) / headerFrame.height
            } else {
                return adjustedHeaderHeight / headerFrame.height
            }
        }

        return max(1, t)
    }

    func body(content: Content) -> some View {
        content
            .background(alignment: .top) {
                MirrorExtensionView(edges: .top) {
                    background
                }
                .onFrameChanged { frame, _ in
                    if headerFrame == .zero || headerFrame.height.isNaN {
                        headerFrame = frame
                    }
                }
                .scaleEffect(scaleEffect, anchor: .top)
                .mask(alignment: .top) {
                    Color.black
                        .frame(height: maskHeight)
                        .offset(y: -scrollViewSafeAreaInsets.top)
                }
                .offset(y: offset)
            }
            .overlay {
                VStack {
                    Text("ScrollView Offset: \(scrollViewOffset)")
                    Text("Background Height: \(adjustedHeaderHeight)")
                    Text("Parent Safe Area Insets: \(scrollViewSafeAreaInsets.top)")

                    Text("--")

                    Text("Background Offset: \(offset)")
//                    Text("Mask Height: \(maskHeight)")
                    Text("Scale Effect: \(scaleEffect)")
                    Text("MaxY: \(frameForParentView[.scrollViewHeader, default: .zero].frame.maxY)")
                    Text("NBH: \(navigationBarHeight)")
                }
                .padding()
                .background(Color.white.opacity(0.2))
                .foregroundStyle(.black)
                .hidden()
            }
    }
}

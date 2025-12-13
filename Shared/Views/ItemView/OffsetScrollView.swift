//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct OffsetScrollView<Header: View, Overlay: View, Content: View>: PlatformView {

        #if os(tvOS)
        @StateObject
        private var focusGuide = FocusGuide()
        #else
        @State
        private var scrollViewOffset: CGFloat = 0
        @State
        private var size: CGSize = .zero
        @State
        private var safeAreaInsets: EdgeInsets = .zero
        #endif

        private let header: Header
        private let overlay: Overlay
        private let content: Content
        private let heightRatio: CGFloat
        private let overlayOffset: CGFloat

        init(
            heightRatio: CGFloat = 0,
            overlayOffset: CGFloat = 150,
            @ViewBuilder header: @escaping () -> Header,
            @ViewBuilder overlay: @escaping () -> Overlay,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.header = header()
            self.overlay = overlay()
            self.content = content()
            self.heightRatio = clamp(heightRatio, min: 0, max: 1)
            self.overlayOffset = overlayOffset
        }

        #if !os(tvOS)
        private var headerHeight: CGFloat {
            (size.height + safeAreaInsets.vertical) * heightRatio
        }

        private var headerOpacity: CGFloat {
            let start = headerHeight - safeAreaInsets.top - 90
            let end = headerHeight - safeAreaInsets.top - 40
            let diff = end - start
            return clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
        }
        #endif

        // MARK: - iOS View

        var iOSView: some View {
            #if os(tvOS)
            EmptyView()
            #else
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
                        Color.systemFill
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
            #endif
        }

        // MARK: - tvOS View

        var tvOSView: some View {
            #if os(tvOS)
            GeometryReader { proxy in
                ZStack {
                    header

                    ScrollView(.vertical, showsIndicators: false) {
                        VStack(spacing: 0) {
                            overlay
                                .focusGuide(
                                    focusGuide,
                                    tag: "header",
                                    bottom: "belowHeader"
                                )
                                .edgePadding()
                                .frame(height: proxy.size.height - overlayOffset)

                            content
                                .focusGuide(
                                    focusGuide,
                                    tag: "belowHeader",
                                    top: "header"
                                )
                        }
                        .background {
                            tvOSBlurBackground(height: proxy.size.height - overlayOffset)
                        }
                        .environmentObject(focusGuide)
                    }
                }
            }
            .ignoresSafeArea()
            #else
            EmptyView()
            #endif
        }

        // MARK: - tvOS Blur Background

        #if os(tvOS)
        @ViewBuilder
        private func tvOSBlurBackground(height: CGFloat) -> some View {
            BlurView(style: .dark)
                .mask {
                    VStack(spacing: 0) {
                        LinearGradient(
                            stops: [
                                .init(color: .white, location: 0),
                                .init(color: .white.opacity(0.7), location: 0.4),
                                .init(color: .white.opacity(0), location: 1),
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                        .frame(height: height)

                        Color.white
                    }
                }
        }
        #endif
    }
}

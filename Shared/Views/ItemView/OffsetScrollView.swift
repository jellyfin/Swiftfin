//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct OffsetScrollView<Header: View, Overlay: View, Content: View>: View {

        #if os(tvOS)
        @StateObject
        private var focusGuide = FocusGuide()
        #endif

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

        #if os(tvOS)
        private let overlayColor: Color = .black
        #else
        private let overlayColor: Color = .systemFill
        #endif

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
        }

        private var headerHeight: CGFloat {
            (size.height + safeAreaInsets.vertical) * heightRatio
        }

        private var headerOpacity: CGFloat {
            let start = headerHeight - safeAreaInsets.top - 90
            let end = headerHeight - safeAreaInsets.top - 40
            let diff = end - start
            return clamp((scrollViewOffset - start) / diff, min: 0, max: 1)
        }

        // MARK: - Body

        var body: some View {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    overlaySection
                    contentSection
                }
                #if os(tvOS)
                .environmentObject(focusGuide)
                #endif
            }
            .ignoresSafeArea()
            .trackingSize($size, $safeAreaInsets)
            .scrollViewOffset($scrollViewOffset)
            .backgroundParallaxHeader(
                $scrollViewOffset,
                height: headerHeight,
                multiplier: 0.3
            ) {
                header
                    .frame(height: headerHeight)
            }
            #if !os(tvOS)
            .navigationBarOffset(
                $scrollViewOffset,
                start: headerHeight - safeAreaInsets.top - 45,
                end: headerHeight - safeAreaInsets.top - 5
            )
            #endif
        }

        // MARK: - Overlay Section

        @ViewBuilder
        private var overlaySection: some View {
            AlternateLayoutView {
                Color.clear
                    .frame(height: headerHeight, alignment: .bottom)
            } content: {
                overlay
                    .frame(height: headerHeight, alignment: .bottom)
                #if os(tvOS)
                    .padding(.edgeInsets)
                    .padding(.bottom, safeAreaInsets.trailing)
                #endif
            }
            .background(alignment: .bottom) {
                overlayBackground
            }
            .overlay {
                overlayColor
                    .opacity(headerOpacity)
            }
            #if os(tvOS)
            .focusGuide(focusGuide, tag: "header", bottom: "belowHeader")
            #endif
        }

        // MARK: - Overlay Background

        @ViewBuilder
        private var overlayBackground: some View {
            #if os(tvOS)
            LinearGradient(
                stops: [
                    .init(color: .clear, location: 0),
                    .init(color: .black, location: 1),
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: headerHeight * 0.6)
            .padding(.horizontal, -safeAreaInsets.horizontal)
            #else
            BlurView(style: .systemThinMaterialDark)
                .frame(height: headerHeight * 0.6)
                .maskLinearGradient {
                    (location: 0.5, opacity: 0)
                    (location: 0.8, opacity: 1)
                }
            #endif
        }

        // MARK: - Content Section

        @ViewBuilder
        private var contentSection: some View {
            content
            #if os(tvOS)
            .background {
                Color.black
                    /// Needed to prevent the background from clipping through when moving too quickly
                        .padding(.top, -5)
            }
            .focusGuide(focusGuide, tag: "belowHeader", top: "header")
            #endif
        }
    }
}

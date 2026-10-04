//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension VideoPlayer {

    struct VideoLayout {

        private let aspectRatio: CGFloat?
        let behavior: ViewState.AspectFillBehavior
        let renderSize: CGSize
        let renderScale: CGFloat

        init(
            videoSize: CGSize,
            viewportSize: CGSize,
            behavior: ViewState.AspectFillBehavior
        ) {
            self.aspectRatio = videoSize.aspectRatio
            self.behavior = behavior

            let geometry = Self.renderGeometry(aspectRatio: aspectRatio, viewportSize: viewportSize, behavior: behavior)
            self.renderSize = geometry.size
            self.renderScale = geometry.scale
        }

        private static func renderGeometry(
            aspectRatio: CGFloat?,
            viewportSize: CGSize,
            behavior: ViewState.AspectFillBehavior
        ) -> (size: CGSize, scale: CGFloat) {
            if let aspectRatio, viewportSize.aspectRatio != nil {
                let height = viewportSize.width / aspectRatio
                let heightScale = viewportSize.height / height

                if height.isFinite, height > 0, heightScale.isFinite {
                    return (
                        CGSize(width: viewportSize.width, height: height),
                        behavior == .fill ? max(1, heightScale) : min(1, heightScale)
                    )
                }
            }
            return (viewportSize, 1)
        }

        func videoFrame(in bounds: CGRect) -> CGRect {
            let geometry = Self.renderGeometry(aspectRatio: aspectRatio, viewportSize: bounds.size, behavior: behavior)
            let size = CGSize(width: geometry.size.width * geometry.scale, height: geometry.size.height * geometry.scale)
            guard size.width.isFinite, size.height.isFinite else { return bounds }

            return CGRect(
                x: bounds.midX - size.width / 2,
                y: bounds.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
        }

        #if os(iOS)
        static func padding(
            insets: EdgeInsets,
            behavior: ViewState.AspectFillBehavior
        ) -> EdgeInsets {
            guard behavior == .fit else { return .init() }

            let horizontalInset = max(insets.leading, insets.trailing)
            return EdgeInsets(
                top: insets.top,
                leading: horizontalInset,
                bottom: insets.bottom,
                trailing: horizontalInset
            )
        }
        #endif
    }

    struct VideoViewport<Content: View>: View {

        @Environment(ViewState.self)
        private var viewState

        @ObservedObject
        var videoSize: PublishedBox<CGSize>

        @ViewBuilder
        let content: (VideoLayout) -> Content

        private var viewport: some View {
            GeometryReader { viewport in
                content(VideoLayout(
                    videoSize: videoSize.value,
                    viewportSize: viewport.size,
                    behavior: viewState.aspectFillBehavior
                ))
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }

        var body: some View {
            #if os(iOS)
            NotchReader { notchMeasurement in
                let usesSystemSafeArea = viewState.isCompact && notchMeasurement?.cutout == nil
                viewport
                    .padding(usesSystemSafeArea ? EdgeInsets() : VideoLayout.padding(
                        insets: notchMeasurement?.insets ?? .init(),
                        behavior: viewState.aspectFillBehavior
                    ))
                    .opacity(viewState.aspectFillBehavior == .fill || notchMeasurement != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2), value: viewState.aspectFillBehavior)
                    .ignoresSafeArea(
                        .container,
                        edges: viewState.aspectFillBehavior == .fill || !usesSystemSafeArea ? .all : []
                    )
            }
            #else
            viewport
                .animation(.easeInOut(duration: 0.2), value: viewState.aspectFillBehavior)
                .ignoresSafeArea(.container)
            #endif
        }
    }
}

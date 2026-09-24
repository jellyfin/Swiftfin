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

        let aspectRatio: CGFloat?
        let behavior: ViewState.AspectFillBehavior
        let scale: CGFloat

        init(
            videoSize: CGSize,
            viewportSize: CGSize,
            behavior: ViewState.AspectFillBehavior
        ) {
            self.aspectRatio = videoSize.aspectRatio
            self.behavior = behavior

            if behavior == .fill,
               let videoAspectRatio = aspectRatio,
               let viewportAspectRatio = viewportSize.aspectRatio
            {
                let relativeRatio = videoAspectRatio / viewportAspectRatio
                let scale = max(relativeRatio, 1 / relativeRatio)
                self.scale = scale.isFinite ? scale : 1
            } else {
                self.scale = 1
            }
        }

        func videoFrame(in bounds: CGRect) -> CGRect {
            guard let aspectRatio, let viewportAspectRatio = bounds.size.aspectRatio else { return bounds }

            let fittedSize = aspectRatio > viewportAspectRatio
                ? CGSize(width: bounds.width, height: bounds.width / aspectRatio)
                : CGSize(width: bounds.height * aspectRatio, height: bounds.height)
            let size = CGSize(width: fittedSize.width * scale, height: fittedSize.height * scale)
            guard size.width.isFinite, size.height.isFinite else { return bounds }

            return CGRect(
                x: bounds.midX - size.width / 2,
                y: bounds.midY - size.height / 2,
                width: size.width,
                height: size.height
            )
        }

        static func padding(
            safeAreaInsets: EdgeInsets,
            hasNotch: Bool,
            isLandscape: Bool,
            behavior: ViewState.AspectFillBehavior,
            fillWithinSafeArea: Bool
        ) -> EdgeInsets {
            guard hasNotch, behavior == .fit || fillWithinSafeArea else { return .init() }
            guard isLandscape else { return safeAreaInsets }

            let horizontalInset = max(safeAreaInsets.leading, safeAreaInsets.trailing)
            return EdgeInsets(top: 0, leading: horizontalInset, bottom: 0, trailing: horizontalInset)
        }
    }

    struct VideoViewport<Content: View>: View {

        @Environment(ViewState.self)
        private var viewState

        @ObservedObject
        var videoSize: PublishedBox<CGSize>

        let fillWithinSafeArea: Bool
        let hasNotch: Bool

        @ViewBuilder
        let content: (VideoLayout) -> Content

        var body: some View {
            GeometryReader { safeGeometry in
                GeometryReader { viewport in
                    content(VideoLayout(
                        videoSize: videoSize.value,
                        viewportSize: viewport.size,
                        behavior: viewState.aspectFillBehavior
                    ))
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
                .padding(VideoLayout.padding(
                    safeAreaInsets: safeGeometry.safeAreaInsets,
                    hasNotch: hasNotch,
                    // A compact supplement can make a portrait phone's viewport wide.
                    isLandscape: !viewState.isCompact && safeGeometry.size.isLandscape,
                    behavior: viewState.aspectFillBehavior,
                    fillWithinSafeArea: fillWithinSafeArea
                ))
                .ignoresSafeArea(.container)
                .animation(.easeInOut(duration: 0.2), value: viewState.aspectFillBehavior)
                .animation(.easeInOut(duration: 0.2), value: fillWithinSafeArea)
            }
        }
    }
}

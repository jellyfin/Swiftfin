//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension ItemView {

    struct BlurredNavigationBarScrollView<Content: View>: View {

        private let content: Content

        init(@ViewBuilder content: @escaping () -> Content) {
            self.content = content()
        }

        var body: some View {
            WithBlurNavigationBar {
                _Body(content: content)
            }
            .ignoresSafeArea()
            .trackingFrame(for: .scrollView)
        }
    }

    private struct _Body<Content: View>: View {

        @Environment(\.frameForParentView)
        private var frameForParentView

        let content: Content

        var body: some View {
            ScrollView {
                content
            }
            .ignoresSafeArea(edges: .horizontal)
            .scrollIndicators(.hidden)
            .overlay(alignment: .top) {
                Rectangle()
                    .fill(Material.ultraThin)
                    .mask(gradient: .eased(.smootherstep)) {
                        (location: 0, opacity: 1)
                        (location: 1, opacity: 0)
                    }
                    .frame(
                        height: frameForParentView[.scrollView, default: .zero]
                            .safeAreaInsets.top + 20
                    )
                    .offset(
                        y: -frameForParentView[.scrollView, default: .zero]
                            .safeAreaInsets.top
                    )
                    .colorScheme(.dark)
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
            }
        }
    }
}

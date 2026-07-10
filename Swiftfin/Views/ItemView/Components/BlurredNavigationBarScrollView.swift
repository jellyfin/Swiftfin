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

        @Environment(\.frameForParentView)
        private var frameForParentView

        private let content: Content
        private let isEnabled: Bool

        init(
            isEnabled: Bool = true,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.content = content()
            self.isEnabled = isEnabled
        }

        var body: some View {
            OffsetNavigationBar(isEnabled: isEnabled) {
                _Body { content }
            }
            .trackingFrame(for: .scrollView)
        }
    }

    private struct _Body<Content: View>: View {

        @Environment(\.frameForParentView)
        private var frameForParentView

        private let content: Content
        private let usesOffsetNavigationBar: Bool

        init(
            usesOffsetNavigationBar: Bool = true,
            @ViewBuilder content: @escaping () -> Content
        ) {
            self.content = content()
            self.usesOffsetNavigationBar = usesOffsetNavigationBar
        }

        var body: some View {
            ScrollView {
                content
            }
            .ignoresSafeArea(edges: .horizontal)
            .scrollIndicators(.hidden)
            .overlay(alignment: .top) {
                if usesOffsetNavigationBar {
                    Rectangle()
                        .fill(Material.ultraThin)
                        .mask {
                            EasedGradient(
                                colors: [.white, .clear],
                                startPoint: .top,
                                endPoint: .bottom,
                                curve: .smootherstep
                            )
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
}

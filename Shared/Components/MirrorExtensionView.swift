//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct MirrorExtensionView<Content: View>: View {

    @State
    private var contentFrame: CGRect = .zero

    private let content: Content
    private let edges: Edge.Set

    init(edges: Edge.Set, @ViewBuilder content: () -> Content) {
        self.content = content()
        self.edges = edges
    }

    @ViewBuilder
    private var mirroredContent: some View {
        ZStack {
            content

            content
                .blur(radius: 5)

            content
                .blur(radius: 20)
        }
    }

    var body: some View {
        content
            .trackingFrame($contentFrame)
            .overlay(alignment: .top) {
                if edges.contains(.top) {
                    mirroredContent
                        .scaleEffect(y: -1, anchor: .top)
                }
            }
            .overlay(alignment: .bottom) {
                if edges.contains(.bottom) {
                    mirroredContent
                        .scaleEffect(y: -1, anchor: .bottom)
                }
            }
    }
}

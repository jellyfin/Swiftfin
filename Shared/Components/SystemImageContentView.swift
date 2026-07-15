//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: bottom view can probably just be cleaned up and change
//       usages to use local background views
// TODO: use heirarchical styles instead of explicit color

struct ContainerRelativeView<Content: View>: View {

    private let content: Content
    private let ratio: CGSize

    init(
        ratio: CGFloat,
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.ratio = CGSize(width: ratio, height: ratio)
    }

    init(
        ratio: CGSize = CGSize(width: 1, height: 1),
        @ViewBuilder content: () -> Content
    ) {
        self.content = content()
        self.ratio = ratio
    }

    var body: some View {
        AlternateLayoutView {
            Color.clear
        } content: { size in
            content
                .frame(width: size.width * ratio.width, height: size.height * ratio.height)
        }
    }
}

struct RelativeSystemImageView: View {

    let systemName: String
    var ratio: CGFloat = 0.5

    var body: some View {
        ContainerRelativeView(ratio: ratio) {
            Image(systemName: systemName)
                .resizable()
                .aspectRatio(contentMode: .fit)
        }
    }
}

struct SystemImageContentView: View {

    let systemName: String?
    var ratio: CGFloat = 0.3

    var body: some View {
        ContainerRelativeView(ratio: ratio) {
            Image(systemName: systemName ?? "circle")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.secondary)
        }
    }
}

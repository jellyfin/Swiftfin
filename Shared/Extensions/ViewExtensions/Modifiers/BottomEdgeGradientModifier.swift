//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BottomEdgeGradientModifier: ViewModifier {

    @State
    private var contentSize: CGSize = .zero

    let bottomColor: Color

    func body(content: Content) -> some View {
        content
            .trackingSize($contentSize)
            .overlay(alignment: .bottom) {
                // Continue the artwork beneath the detail controls, fading the
                // reflection into its resolved color without a seam at the image.
                content
                    .scaleEffect(y: -1)
                    .blur(radius: 5)
                    .clipped()
                    .overlay {
                        EasedGradient(
                            colors: [.clear, bottomColor],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    }
                    .offset(y: contentSize.height)
            }
            .background(alignment: .top, extendedBy: .init(top: 0, leading: 0, bottom: 1000, trailing: 0)) {
                bottomColor
            }
    }
}

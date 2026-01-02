//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: both axes

struct ScrollIfLargerThanContainerModifier: ViewModifier {

    @State
    private var contentFrame: CGRect = .zero

    let padding: CGFloat

    func body(content: Content) -> some View {
        AlternateLayoutView {
            Color.clear
        } content: { layoutSize in
            ScrollView {
                content
                    .trackingFrame($contentFrame)
            }
            .frame(maxHeight: contentFrame.height >= layoutSize.height ? .infinity : contentFrame.height)
            .backport // iOS 17
            .scrollClipDisabled()
            .scrollDisabled(contentFrame.height < layoutSize.height)
            .scrollIndicators(.never)
        }
    }
}

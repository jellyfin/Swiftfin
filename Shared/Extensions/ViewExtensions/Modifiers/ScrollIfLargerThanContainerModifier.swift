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
    private var contentSize: CGSize = .zero
    @State
    private var layoutSize: CGSize = .zero

    let padding: CGFloat

    func body(content: Content) -> some View {
        AlternateLayoutView {
            Color.clear
                .trackingSize($layoutSize)
        } content: {
            ScrollView {
                content
                    .trackingSize($contentSize)
            }
            .frame(maxHeight: contentSize.height >= layoutSize.height ? .infinity : contentSize.height)
            .backport // iOS 17
            .scrollClipDisabled()
            .scrollDisabled(contentSize.height < layoutSize.height)
            .scrollIndicators(.never)
        }
    }
}

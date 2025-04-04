//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: both axes
// TODO: add scrollClipDisabled() to iOS when iOS 15 dropped

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
            #if os(tvOS)
            .scrollClipDisabled()
            #endif
            .frame(maxHeight: contentSize.height >= layoutSize.height ? .infinity : contentSize.height)
            .backport
            .scrollDisabled(contentSize.height < layoutSize.height)
            .backport
            .scrollIndicators(.never)
        }
    }
}

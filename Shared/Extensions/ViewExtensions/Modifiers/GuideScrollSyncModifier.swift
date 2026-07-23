//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI
@_spi(Advanced) import SwiftUIIntrospect

struct GuideScrollSyncModifier: ViewModifier {

    let proxy: GuideScrollProxy
    let nowOffset: CGFloat?

    func body(content: Content) -> some View {
        content.introspect(
            .scrollView,
            on: .iOS(.v15...),
            .tvOS(.v15...)
        ) { scrollView in
            #if os(tvOS)
            scrollView.contentInsetAdjustmentBehavior = .never
            #endif

            proxy.register(
                scrollView,
                nowOffset: nowOffset
            )
        }
    }
}

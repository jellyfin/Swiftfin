//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct TrackingFrameModifier: ViewModifier {

    @Environment(\.frameForParentView)
    private var frameForParentView

    @State
    private var frame: CGRect = .zero
    @State
    private var safeAreaInsets: EdgeInsets = .zero

    let coordinateSpace: CoordinateSpace

    func body(content: Content) -> some View {
        content
            .environment(
                \.frameForParentView,
                frameForParentView.inserting(
                    value: .init(frame: frame, safeAreaInsets: safeAreaInsets),
                    for: coordinateSpace
                )
            )
            .trackingFrame($frame, $safeAreaInsets)
//            .preference(
//                key: FrameForViewPreferenceKey.self,
//                value: .init().inserting(
//                    value: frame,
//                    for: .named(name)
//                )
//            )
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct WithFrame<Content: View>: View {

    @State
    private var frame: FrameAndSafeAreaInsets = .zero

    private let content: (FrameAndSafeAreaInsets) -> Content

    init(@ViewBuilder content: @escaping (FrameAndSafeAreaInsets) -> Content) {
        self.content = content
    }

    var body: some View {
        content(frame)
            .onFrameChanged(perform: { frame, safeArea in
                self.frame = .init(
                    frame: frame,
                    safeAreaInsets: safeArea
                )
            })
    }
}

//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct NavigationBarOffsetModifier: ViewModifier {

    @Binding
    var scrollViewOffset: CGFloat

    let start: CGFloat
    let end: CGFloat

    func body(content: Content) -> some View {
        NavigationBarOffsetView(
            scrollViewOffset: $scrollViewOffset,
            start: start,
            end: end
        ) {
            content
        }
        .ignoresSafeArea()
    }
}

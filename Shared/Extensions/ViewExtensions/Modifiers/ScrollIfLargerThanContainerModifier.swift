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

    let padding: CGFloat

    func body(content: Content) -> some View {
        ViewThatFits(in: .vertical) {
            // if content is small
            content

            // if content too tall
            ScrollView {
                content
            }
            .backport // iOS 17
            .scrollClipDisabled()
            .scrollIndicators(.never)
        }
    }
}

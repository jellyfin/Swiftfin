//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ScrollIfLargerThanModifier: ViewModifier {

    @State
    private var contentSize: CGSize = .zero

    let height: CGFloat

    func body(content: Content) -> some View {
        ScrollView {
            content
                .trackingSize($contentSize)
        }
        .backport
        .scrollDisabled(contentSize.height < height)
        .frame(maxHeight: contentSize.height >= height ? .infinity : contentSize.height)
    }
}

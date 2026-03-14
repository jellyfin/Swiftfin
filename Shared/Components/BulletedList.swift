//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

func BulletedList(
    spacing: CGFloat = 8,
    @ViewBuilder content: @escaping () -> some View
) -> some View {
    MarkedList(spacing: spacing) { _ in
        ZStack {
            // Capture local font line height
            Text(" ")
                .hidden()

            Circle()
                .frame(width: 8)
                .padding(.trailing, 5)
        }
    } content: {
        content()
    }
}

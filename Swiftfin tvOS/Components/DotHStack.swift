//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

func DotHStack<Content: View>(
    padding: CGFloat = 10,
    @ViewBuilder content: @escaping () -> Content
) -> some View {
    SeparatorHStack {
        Circle()
            .frame(width: 5, height: 5)
            .padding(.horizontal, 10)
    } content: {
        content()
    }
}

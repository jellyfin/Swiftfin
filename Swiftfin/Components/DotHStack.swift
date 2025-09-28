//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

func DotHStack(
    padding: CGFloat = 5,
    @ViewBuilder content: @escaping () -> some View
) -> some View {
    SeparatorHStack {
        Circle()
            .frame(width: 2, height: 2)
            .padding(.horizontal, padding)
    } content: {
        content()
    }
}

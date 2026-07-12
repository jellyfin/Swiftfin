//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if os(tvOS)
private let dotHStackDotSize: CGFloat = 5
private let dotHStackPadding: CGFloat = 10
#else
private let dotHStackDotSize: CGFloat = 2
private let dotHStackPadding: CGFloat = 5
#endif

func DotHStack(
    padding: CGFloat = dotHStackPadding,
    @ViewBuilder content: @escaping () -> some View
) -> some View {
    SeparatorHStack {
        Circle()
            .frame(width: dotHStackDotSize, height: dotHStackDotSize)
            .padding(.horizontal, padding)
    } content: {
        content()
    }
}

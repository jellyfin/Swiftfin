//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

#if os(iOS)
private let defaultPadding: CGFloat = 5
private let defaultCircleSize: CGFloat = 2
#else
private let defaultPadding: CGFloat = 10
private let defaultCircleSize: CGFloat = 5
#endif

func DotHStack(
    padding: CGFloat = defaultPadding,
    @ViewBuilder content: @escaping () -> some View
) -> some View {
    SeparatorHStack {
        Circle()
            .frame(
                width: defaultCircleSize,
                height: defaultCircleSize
            )
            .padding(.horizontal, padding)
    } content: {
        content()
    }
}

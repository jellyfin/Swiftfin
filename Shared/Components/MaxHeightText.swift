//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: anchor for scaleEffect?
// TODO: try an implementation that doesn't require passing in the height

/// A `Text` wrapper that will scale down the underlying `Text` view
/// if the height is greater than the given `maxHeight`.
struct MaxHeightText: View {

    @State
    private var scale = 1.0

    let text: String
    let maxHeight: CGFloat

    var body: some View {
        Text(text)
            .fixedSize(horizontal: false, vertical: true)
            .hidden()
            .overlay {
                Text(text)
                    .scaleEffect(CGSize(width: scale, height: scale), anchor: .bottom)
            }
            .onSizeChanged { newSize, _ in
                if newSize.height > maxHeight {
                    scale = maxHeight / newSize.height
                }
            }
    }
}

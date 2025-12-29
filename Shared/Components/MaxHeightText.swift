//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// A `Text` wrapper that will scale down its text
/// if its height is greater than its container
struct MaxHeightText: View {

    private let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        AlternateLayoutView {
            Color.clear
        } content: { layoutSize in
            WithFrame { textFrame in
                Text(text)
                    .fixedSize(horizontal: true, vertical: false)
                    .hidden()
                    .debugOverlay(.blue.opacity(0.5))
                    .overlay(alignment: .bottom) {
                        let scale = textFrame.height > layoutSize.height
                            ? layoutSize.height / textFrame.height
                            : 1.0

                        Text(text)
                            .scaleEffect(x: scale, y: scale, anchor: .bottom)
                            .debugOverlay(.yellow.opacity(0.5))
                    }
            }
        }
        .debugOverlay(.red.opacity(0.5))
    }
}

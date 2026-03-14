//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: remove and replace with `PlaybackProgressViewStyle`
struct ProgressBar: View {

    @State
    private var contentSize: CGSize = .zero

    let progress: CGFloat

    var body: some View {
        Capsule()
            .foregroundStyle(.secondary)
            .opacity(0.2)
            .overlay(alignment: .leading) {
                Capsule()
                    .mask(alignment: .leading) {
                        Rectangle()
                    }
                    .frame(width: contentSize.width * progress)
                    .foregroundStyle(.primary)
            }
            .trackingSize($contentSize)
    }
}

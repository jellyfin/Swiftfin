//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

// TODO: see if animation is correct here or should be in caller views

struct ProgressBar: View {

    let progress: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .foregroundColor(.secondary)
                .opacity(0.2)

            Capsule()
                .mask(alignment: .leading) {
                    Rectangle()
                        .scaleEffect(x: progress, anchor: .leading)
                }
        }
        .animation(.linear(duration: 0.1), value: progress)
    }
}

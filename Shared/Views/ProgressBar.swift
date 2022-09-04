//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct ProgressBar: View {

    let progress: CGFloat

    var body: some View {
        ZStack(alignment: .leading) {
            Capsule()
                .foregroundColor(.white)
                .opacity(0.2)

            Capsule()
                .foregroundColor(.jellyfinPurple)
                .scaleEffect(x: progress, y: 1, anchor: .leading)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 3)
    }
}

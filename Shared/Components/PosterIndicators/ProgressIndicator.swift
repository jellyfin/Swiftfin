//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import Defaults
import JellyfinAPI
import SwiftUI

struct ProgressIndicator: View {

    @Default(.accentColor)
    private var accentColor

    let progress: CGFloat
    let height: CGFloat

    var body: some View {
        VStack {
            Spacer()

            accentColor
                .scaleEffect(x: progress, y: 1, anchor: .leading)
                .frame(height: height)
        }
        .frame(maxWidth: .infinity)
    }
}

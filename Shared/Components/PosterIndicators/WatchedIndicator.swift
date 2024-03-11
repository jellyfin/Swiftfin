//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct WatchedIndicator: View {

    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            Image(systemName: "checkmark.circle.fill")
                .resizable()
                .frame(width: size, height: size)
                .paletteOverlayRendering(color: .white)
                .padding(3)
        }
    }
}

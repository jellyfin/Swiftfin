//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct WatchedIndicator: View {

    let size: CGFloat

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Color.clear

            // A plain white checkmark with a soft shadow — matching the home rows' watched
            // indicator — instead of a filled circle (which became invisible once the accent
            // color, the circle's fill, was set to white).
            Image(systemName: "checkmark")
                .font(.system(size: size * 0.62, weight: .bold))
                .foregroundStyle(.white)
                .shadow(color: .black.opacity(0.6), radius: 3)
                .padding(size * 0.18)
        }
    }
}

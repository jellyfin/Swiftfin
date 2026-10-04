//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct VideoZoomBorder: View {

    let isVisible: Bool

    var body: some View {
        NotchReader { measurement in
            RoundedRectangle(cornerRadius: measurement?.displayCornerRadius ?? 0, style: .continuous)
                .strokeBorder(.white.opacity(0.3), lineWidth: 18)
        }
        .ignoresSafeArea(.container)
        .opacity(isVisible ? 1 : 0)
        .animation(.easeOut(duration: 0.18), value: isVisible)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

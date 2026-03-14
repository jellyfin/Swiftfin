//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct BottomEdgeGradientModifier: ViewModifier {

    let bottomColor: Color

    func body(content: Content) -> some View {
        VStack(spacing: 0) {
            content
                .overlay {
                    bottomColor
                        .maskLinearGradient {
                            (location: 0.8, opacity: 0)
                            (location: 0.95, opacity: 1)
                        }
                }

            bottomColor
        }
    }
}

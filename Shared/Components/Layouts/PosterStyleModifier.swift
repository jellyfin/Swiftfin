//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct PosterStyleModifier: ViewModifier {
    @AdaptiveLayout
    private var viewLayout

    let type: PosterDisplayType
    let contentMode: ContentMode

    func body(content: Content) -> some View {
        content
            .posterAspectRatio(type, contentMode: contentMode)
            .if(!viewLayout.isLarge) { poster in
                // Focus button styles supply their own border and clipping shape.
                poster.posterBorder().posterCornerRadius(type)
            }
    }
}

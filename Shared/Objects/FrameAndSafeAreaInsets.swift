//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FrameAndSafeAreaInsets: Equatable {

    let frame: CGRect
    let safeAreaInsets: EdgeInsets

    var sizeIncludingSafeArea: CGSize {
        CGSize(
            width: frame.width + safeAreaInsets.leading + safeAreaInsets.trailing,
            height: frame.height + safeAreaInsets.top + safeAreaInsets.bottom
        )
    }

    static let zero = Self(frame: .zero, safeAreaInsets: .zero)
}

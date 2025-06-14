//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2025 Jellyfin & Jellyfin Contributors
//

import SwiftUI

struct FramePreferenceKey: PreferenceKey {

    struct Value: Equatable {
        let frame: CGRect
        let safeAreaInsets: EdgeInsets
    }

    static var defaultValue: Value = Value(
        frame: .zero,
        safeAreaInsets: .zero
    )

    static func reduce(value: inout Value, nextValue: () -> Value) {}
}

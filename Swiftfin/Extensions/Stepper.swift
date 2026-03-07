//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Stepper {

    init<V: Strideable>(
        _ title: String,
        value: Binding<V>,
        in range: ClosedRange<V>,
        step: V.Stride = 1,
        @ViewBuilder label: @escaping () -> Label
    ) {
        self.init(value: value, in: range, step: step, label: label)
    }
}

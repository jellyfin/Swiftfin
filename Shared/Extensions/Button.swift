//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2023 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension Button where Label: View {

    /// Creates a Button with an empty action and a custom label.
    init(@ViewBuilder label: @escaping () -> Label) {
        self.init {} label: {
            label()
        }
    }
}

extension Button where Label == Text {

    /// Creates a Button with an empty action and a plain text label.
    init(_ title: String) {
        self.init {
            Text(title)
        }
    }
}

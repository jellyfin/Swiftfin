//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

extension View {

    /// Clips content to its horizontal bounds while leaving vertical overflow, like shadows, visible.
    func clipHorizontalOverflow() -> some View {
        #if os(iOS)
        mask(extendedBy: .init(vertical: EdgeInsets.edgePadding * 2)) {
            Rectangle()
        }
        #else
        self
        #endif
    }
}

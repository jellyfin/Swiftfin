//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import SwiftUI

/// Focus identities for ItemView on tvOS.
///
/// `play` must be applied to the focusable Play button. Preferring the
/// non-focusable header container lets poster rows win initial focus.
enum ItemViewFocusID {
    static let header = "itemView-header"
    static let play = "itemView-play"
}

extension EnvironmentValues {

    @Entry
    var itemViewFocusedGroupID: FocusState<String?>.Binding?
}

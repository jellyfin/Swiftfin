//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

// TODO: Flat design

struct AboutItemGroup: _ContentGroup {

    let displayTitle: String
    let id: String
    let item: BaseItemDto

    var _shouldBeResolved: Bool { false }

    func body(with viewModel: Empty) -> some View {
        EmptyView()
    }
}

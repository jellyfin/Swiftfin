//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2026 Jellyfin & Jellyfin Contributors
//

import JellyfinAPI
import SwiftUI

struct EnhancedItemViewHeader: ContentGroup {

    let id = "item-view-header"
    let viewModel: Empty = .init()
    let itemViewModel: ItemViewModel

    func body(with viewModel: Empty) -> some View {
        if UIDevice.isPhone {
            CompactBody(viewModel: itemViewModel)
        } else {
            RegularBody(viewModel: itemViewModel)
        }
    }
}

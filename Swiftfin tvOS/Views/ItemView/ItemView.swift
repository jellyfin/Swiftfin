//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2022 Jellyfin & Jellyfin Contributors
//

import Defaults
import Introspect
import JellyfinAPI
import SwiftUI

struct ItemView: View {

    private let item: BaseItemDto

    init(item: BaseItemDto) {
        self.item = item
    }

    var body: some View {
        Group {
            switch item.type {
            case .movie:
                MovieItemView(viewModel: .init(item: item))
            case .episode:
                Text("Help")
            case .season:
                Text("Help")
            case .series:
                SeriesItemView(viewModel: .init(item: item))
//            case .boxset, .folder:
//                Text("Help")
            default:
                Text(L10n.notImplementedYetWithType(item.type ?? ""))
            }
        }
    }
}

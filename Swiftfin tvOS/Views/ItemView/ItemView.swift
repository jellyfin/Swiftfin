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
        switch item.type {
        case .movie:
            MovieItemView(viewModel: .init(item: item))
        case .episode:
            EpisodeItemView(viewModel: .init(item: item))
        case .series:
            SeriesItemView(viewModel: .init(item: item))
        case .boxSet:
            CollectionItemView(viewModel: .init(item: item))
        default:
            Text(L10n.notImplementedYetWithType(item.type ?? "--"))
        }
    }
}

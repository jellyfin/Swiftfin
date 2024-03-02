//
// Swiftfin is subject to the terms of the Mozilla Public
// License, v2.0. If a copy of the MPL was not distributed with this
// file, you can obtain one at https://mozilla.org/MPL/2.0/.
//
// Copyright (c) 2024 Jellyfin & Jellyfin Contributors
//

import Introspect
import JellyfinAPI
import SwiftUI
import WidgetKit

struct ItemView: View {

    let item: BaseItemDto

    var body: some View {
        Group {
            switch item.type {
            case .movie:
                if UIDevice.isPad {
                    iPadOSMovieItemView(viewModel: .init(item: item))
                } else {
                    MovieItemView(viewModel: .init(item: item))
                }
            case .series:
                if UIDevice.isPad {
                    iPadOSSeriesItemView(viewModel: .init(item: item))
                } else {
                    SeriesItemView(viewModel: .init(item: item))
                }
            case .episode:
                if UIDevice.isPad {
                    iPadOSEpisodeItemView(viewModel: .init(item: item))
                } else {
                    EpisodeItemView(viewModel: .init(item: item))
                }
            case .boxSet:
                if UIDevice.isPad {
                    iPadOSCollectionItemView(viewModel: .init(item: item))
                } else {
                    CollectionItemView(viewModel: .init(item: item))
                }
            default:
                Text(L10n.notImplementedYetWithType(item.type ?? "--"))
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(item.displayTitle)
    }
}

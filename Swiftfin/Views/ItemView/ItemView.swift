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

    @ViewBuilder
    private var padView: some View {
        switch item.type {
        case .boxSet:
            iPadOSCollectionItemView(item: item)
        case .episode:
            iPadOSEpisodeItemView(item: item)
        case .movie:
            iPadOSMovieItemView(item: item)
        case .series:
            iPadOSSeriesItemView(item: item)
        default:
            Text(L10n.notImplementedYetWithType(item.type ?? "--"))
        }
    }

    @ViewBuilder
    private var phoneView: some View {
        switch item.type {
        case .boxSet:
            CollectionItemView(item: item)
        case .episode:
            EpisodeItemView(item: item)
        case .movie:
            MovieItemView(item: item)
        case .series:
            SeriesItemView(item: item)
        default:
            Text(L10n.notImplementedYetWithType(item.type ?? "--"))
        }
    }

    var body: some View {
        WrappedView {
            if UIDevice.isPad {
                padView
            } else {
                phoneView
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(item.displayTitle)
    }
}
